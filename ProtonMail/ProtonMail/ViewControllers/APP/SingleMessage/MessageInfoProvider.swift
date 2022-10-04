// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Services
import ProtonCore_UIFoundations

protocol MessageInfoProviderDelegate: AnyObject {
    func update(senderContact: ContactVO?)
    func hideDecryptionErrorBanner()
    func showDecryptionErrorBanner()
    func updateBannerStatus()
    func update(content: WebContents?)
    func update(hasStrippedVersion: Bool)
    func update(renderStyle: MessageRenderStyle)
    func sendDarkModeMetric(isApply: Bool)
    func updateAttachments()
}

private enum EmbeddedDownloadStatus {
    case none, downloading, finish
}

final class MessageInfoProvider {
    private(set) var message: MessageEntity {
        willSet {
            let bodyHasChanged = message.body != newValue.body
            if bodyHasChanged {
                bodyParts = nil
                hasAutoRetriedDecrypt = false
            }
        }
        didSet {
            pgpChecker = MessageSenderPGPChecker(message: message, user: user)
            prepareDisplayBody()
            checkSenderPGP()
        }
    }
    private let contactService: ContactDataService
    private let contactGroupService: ContactGroupsDataService
    private let messageDecrypter: MessageDecrypterProtocol
    private let messageService: MessageDataService
    private let userAddressUpdater: UserAddressUpdaterProtocol
    private let systemUpTime: SystemUpTimeProtocol
    private let user: UserManager
    private let labelID: LabelID
    private weak var delegate: MessageInfoProviderDelegate?
    private var pgpChecker: MessageSenderPGPChecker?
    private let prepareDisplayBodyQueue = DispatchQueue(label: "me.proton.mail.prepareDisplayBody")

    init(
        message: MessageEntity,
        messageDecrypter: MessageDecrypterProtocol? = nil,
        user: UserManager,
        systemUpTime: SystemUpTimeProtocol,
        labelID: LabelID
    ) {
        self.message = message
        self.pgpChecker = MessageSenderPGPChecker(message: message, user: user)
        self.user = user
        self.contactService = user.contactService
        self.contactGroupService = user.contactGroupService
        self.messageService = user.messageService
        self.messageDecrypter = messageDecrypter ?? messageService.messageDecrypter
        let shouldAutoLoadRemoteImages = user.userInfo.showImages.contains(.remote)
        self.remoteContentPolicy = shouldAutoLoadRemoteImages ? .allowed : .disallowed
        let shouldAutoLoadEmbeddedImages = user.userInfo.showImages.contains(.embedded)
        self.embeddedContentPolicy = shouldAutoLoadEmbeddedImages ? .allowed : .disallowed
        self.userAddressUpdater = user
        self.systemUpTime = systemUpTime
        self.labelID = labelID

        if message.isPlainText {
            self.currentMessageRenderStyle = .dark
        } else {
            self.currentMessageRenderStyle = message.isNewsLetter ? .lightOnly : .dark
        }
    }

    func initialize() {
        self.prepareDisplayBody()
        self.checkSenderPGP()
    }

    lazy var senderName: String = {
        guard let senderInfo = message.sender else {
            assert(false, "Sender with no name or address")
            return ""
        }
        guard let contactName = contactService.getName(of: senderInfo.email) else {
            return senderInfo.name.isEmpty ? senderInfo.email : senderInfo.name
        }
        return contactName
    }()

    private(set) var checkedSenderContact: ContactVO? {
        didSet {
            delegate?.update(senderContact: checkedSenderContact)
        }
    }

    var initials: String { senderName.initials() }

    var senderEmail: String { "\((message.sender?.email ?? ""))" }

    var time: String {
        if message.contains(location: .scheduled), let date = message.time {
            return dateFormatter.stringForScheduledMsg(from: date)
        } else if let date = message.time {
            return dateFormatter.string(from: date, weekStart: user.userInfo.weekStartValue)
        } else {
            return .empty
        }
    }

    private lazy var dateFormatter: PMDateFormatter = {
        return PMDateFormatter.shared
    }()

    lazy var date: String? = {
        guard let date = message.time else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .long
        dateFormatter.timeZone = Environment.timeZone
        dateFormatter.locale = Environment.locale()
        return dateFormatter.string(from: date)
    }()

    func originImage(isExpanded: Bool) -> UIImage? {
        if isExpanded && message.isSent {
            // In expanded header, we prioritize to show the sent location.
            return LabelLocation.sent.icon
        }

        let id = message.messageLocation?.labelID ?? labelID
        if let image = message.getLocationImage(in: id) {
            return image
        }
        return message.isCustomFolder ? IconProvider.folder : nil
    }

    func originFolderTitle(isExpanded: Bool) -> String? {
        if isExpanded && message.isSent {
            // In expanded header, we prioritize to show the sent location.
            return LabelLocation.sent.localizedTitle
        }

        if let locationName = message.messageLocation?.localizedTitle {
            return locationName
        }
        return message.customFolder?.name
    }

    var size: String { message.size.toByteCount }

    private lazy var groupContacts: [ContactGroupVO] = { [unowned self] in
        contactGroupService.getAllContactGroupVOs()
    }()

    private var userContacts: [ContactVO] {
        contactService.allContactVOs()
    }

    var simpleRecipient: String? {
        let lists = ContactPickerModelHelper.contacts(from: message.rawCCList)
        + ContactPickerModelHelper.contacts(from: message.rawBCCList)
        + ContactPickerModelHelper.contacts(from: message.rawTOList)
        let groupNames = groupNames(from: lists)
        let receiver = recipientNames(from: lists)
        let result = groupNames + receiver
        let name = result.isEmpty ? "" : result.asCommaSeparatedList(trailingSpace: true)
        let recipients = name.isEmpty ? LocalString._undisclosed_recipients : name
        return recipients
    }

    lazy var toData: ExpandedHeaderRecipientsRowViewModel? = {
        let toList = ContactPickerModelHelper.contacts(from: message.rawTOList)
        var list: [ContactVO] = toList.compactMap({ $0 as? ContactVO })
        toList
            .compactMap({ $0 as? ContactGroupVO })
            .forEach { group in
                group.getSelectedEmailData()
                    .compactMap { ContactVO(name: $0.name, email: $0.email) }
                    .forEach { list.append($0) }
            }
        return createRecipientRowViewModel(
            from: list,
            title: "\(LocalString._general_to_label):"
        )
    }()

    lazy var ccData: ExpandedHeaderRecipientsRowViewModel? = {
        let list = ContactPickerModelHelper.contacts(from: message.rawCCList).compactMap({ $0 as? ContactVO })
        return createRecipientRowViewModel(from: list, title: "\(LocalString._general_cc_label):")
    }()

    // [cid, base64String]
    private var embeddedBase64: [String: String] = [:]
    private var embeddedStatus = EmbeddedDownloadStatus.none
    private(set) var hasStrippedVersion: Bool = false {
        didSet { delegate?.update(hasStrippedVersion: hasStrippedVersion) }
    }
    private(set) var shouldShowRemoteBanner = false
    private(set) var shouldShowEmbeddedBanner = false
    private var hasAutoRetriedDecrypt = false
    private(set) var bodyParts: BodyParts? {
        didSet {
            hasStrippedVersion = bodyParts?.bodyHasHistory ?? false
            inlineAttachments = inlineImages(in: bodyParts?.originalBody, attachments: message.attachments)
        }
    }
    private(set) var contents: WebContents? {
        didSet { delegate?.update(content: self.contents) }
    }
    private(set) var isBodyDecryptable: Bool = false

    var remoteContentPolicy: WebContents.RemoteContentPolicy {
        didSet {
            guard remoteContentPolicy != oldValue else { return }
            prepareDisplayBody()
        }
    }

    var embeddedContentPolicy: WebContents.EmbeddedContentPolicy {
        didSet {
            guard embeddedContentPolicy != oldValue else { return }
            prepareDisplayBody()
        }
    }

    var displayMode: MessageDisplayMode = .collapsed {
        didSet {
            guard displayMode != oldValue else { return }
            prepareDisplayBody()
        }
    }

    /// This property is used to record the current render style of the message body in the webView.
    var currentMessageRenderStyle: MessageRenderStyle {
        didSet {
            contents?.renderStyle = currentMessageRenderStyle
            delegate?.update(renderStyle: currentMessageRenderStyle)
        }
        willSet {
            if currentMessageRenderStyle == .dark && newValue == .lightOnly {
                delegate?.sendDarkModeMetric(isApply: false)
            }
            if currentMessageRenderStyle == .lightOnly && newValue == .dark {
                delegate?.sendDarkModeMetric(isApply: true)
            }
        }
    }

    var shouldDisplayRenderModeOptions: Bool {
        if message.isNewsLetter { return false }
        guard let css = self.bodyParts?.darkModeCSS, !css.isEmpty else {
            // darkModeCSS is nil or empty
            return false
        }

        if #available(iOS 12.0, *) {
            return UIApplication.shared.windows[0].traitCollection.userInterfaceStyle == .dark
        } else {
            return false
        }
    }

    /// Queue to update embedded image data
    private lazy var replacementQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private(set) var inlineAttachments: [AttachmentEntity]? {
        didSet {
            guard inlineAttachments != oldValue else { return }
            delegate?.updateAttachments()
        }
    }
    var nonInlineAttachments: [AttachmentEntity] {
        message.attachments.filter { !(inlineAttachments ?? []).contains($0) }
    }

    private(set) var mimeAttachments: [MimeAttachment] = [] {
        didSet {
            guard mimeAttachments != oldValue else { return }
            delegate?.updateAttachments()
        }
    }

    var scheduledSendingTime: (String, String)? {
        guard let time = message.time, message.contains(location: .scheduled) else {
            return nil
        }
        return PMDateFormatter.shared.titleForScheduledBanner(from: time)
    }
}

// MARK: Public functions
extension MessageInfoProvider {
    func update(message: MessageEntity) {
        self.message = message
    }

    func tryDecryptionAgain(handler: (() -> Void)?) {
        userAddressUpdater.updateUserAddresses { [weak self] in
            self?.bodyParts = nil
            self?.prepareDisplayBody()
            self?.prepareDisplayBodyQueue.async {
                handler?()
            }
        }
    }

    func set(delegate: MessageInfoProviderDelegate) {
        self.delegate = delegate
    }
}

// MARK: Contact related
extension MessageInfoProvider {
    private func groupNames(from recipients: [ContactPickerModelProtocol]) -> [String] {
        recipients
            .compactMap { $0 as? ContactGroupVO }
            .map { recipient -> String in
                let groupName = recipient.contactTitle
                let group = groupContacts.first(where: { $0.contactTitle == groupName })
                let total = group?.contactCount ?? 0
                let count = recipient.contactCount
                let name = "\(groupName) (\(count)/\(total))"
                return name
            }
    }

    private func recipientNames(from recipients: [ContactPickerModelProtocol]) -> [String] {
        recipients
            .compactMap { item -> String? in
                guard let contact = item as? ContactVO else {
                    return nil
                }
                guard let name = contactService.getName(of: contact.email) else {
                    let name = contact.displayName ?? ""
                    return name.isEmpty ? contact.displayEmail : name
                }
                return name
            }
    }

    private func checkSenderPGP() {
        guard checkedSenderContact == nil else { return }
        pgpChecker?.check { [weak self] contact in
            self?.checkedSenderContact = contact
        }
    }

    private func createRecipientRowViewModel(
        from contacts: [ContactVO],
        title: String
    ) -> ExpandedHeaderRecipientsRowViewModel? {
        guard !contacts.isEmpty else { return nil }
        let recipients = contacts.map { recipient -> ExpandedHeaderRecipientRowViewModel in
            let email = recipient.email.isEmpty ? "" : "\(recipient.email)"
            let emailToDisplay = email.isEmpty ? "" : "\(email)"
            let nameFromContact = recipient.getName(in: userContacts) ?? .empty
            let name = nameFromContact.isEmpty ? email : nameFromContact
            let contact = ContactVO(name: name, email: recipient.email)
            return ExpandedHeaderRecipientRowViewModel(
                name: name,
                address: emailToDisplay,
                contact: contact
            )
        }
        return ExpandedHeaderRecipientsRowViewModel(
            title: title,
            recipients: recipients
        )
    }
}

// MARK: Body related
extension MessageInfoProvider {
    private func prepareDisplayBody() {
        prepareDisplayBodyQueue.async {
            self.checkAndDecryptBody()
            guard let decryptedBody = self.bodyParts?.originalBody else {
                self.prepareDecryptFailedBody()
                return
            }
            self.updateBodyParts(with: decryptedBody)
            self.checkBannerStatus(decryptedBody)

            guard self.embeddedContentPolicy == .allowed else {
                self.updateWebContents()
                return
            }

            guard self.embeddedStatus == .finish else {
                // If embedded images haven't prepared
                // Display content first
                // Reload view after preparing
                self.updateWebContents()
                self.downloadEmbedImage(self.message)
                return
            }

            self.showEmbeddedImages()
        }
    }

    private func prepareDecryptFailedBody() {
        guard !message.body.isEmpty else { return }
        var rawBody = message.body
        // If the string length is over 60k
        // The web view performance becomes bad
        // Cypher means nothing to human, 30k is enough
        let limit = 30_000
        if rawBody.count >= limit {
            let button = "<a href=\"\(String.fullDecryptionFailedViewLink)\">\(LocalString._show_full_message)</a>"
            let index = rawBody.index(rawBody.startIndex, offsetBy: limit)
            rawBody = String(rawBody[rawBody.startIndex..<index]) + button
            rawBody = "<div>\(rawBody)</div>"
        }
        // If the detail hasn't download, don't show encrypted body to user
        if message.isDetailDownloaded {
            updateBodyParts(with: rawBody)
            updateWebContents()
        }
    }

    private func checkAndDecryptBody() {
        let expiration = message.expirationTime
        let referenceDate = Date.getReferenceDate(processInfo: systemUpTime)
        let expired = (expiration ?? .distantFuture).compare(referenceDate) == .orderedAscending
        guard !expired else {
            updateBodyParts(with: LocalString._message_expired)
            return
        }

        guard message.isDetailDownloaded else {
            return
        }

        let decryptionIsNeeded = bodyParts == nil
        guard decryptionIsNeeded else { return }
        if let result = decryptBody() {
            updateBodyParts(with: result.body)
            mimeAttachments = result.attachments ?? []
        } else {
            bodyParts = nil
            mimeAttachments = []
        }
    }

    private func decryptBody() -> MessageDecrypterProtocol.Output? {
        do {
            let decryptionOutput = try messageDecrypter.decrypt(message: message)
            isBodyDecryptable = true
            delegate?.hideDecryptionErrorBanner()
            return decryptionOutput
        } catch {
            delegate?.showDecryptionErrorBanner()
            if !hasAutoRetriedDecrypt {
                // If failed, auto retry one time
                // Maybe the user just imported a key and event api not sync yet
                hasAutoRetriedDecrypt = true
                tryDecryptionAgain(handler: nil)
            }
            return nil
        }
    }

    private func updateBodyParts(with newBody: String) {
        bodyParts = BodyParts(
            originalBody: newBody,
            isNewsLetter: message.isNewsLetter,
            isPlainText: message.isPlainText
        )
    }

    private func updateWebContents() {
        var body = bodyParts?.body(for: displayMode) ?? ""
        // keyword highlighting of email content
        if #available(iOS 12.0, *) {
            if UserInfo.isEncryptedSearchEnabledPaidUsers || UserInfo.isEncryptedSearchEnabledFreeUsers {
                if self.message.isDraft == false {
                    body = EncryptedSearchService.shared.highlightKeyWords(bodyAsHtml: body)
                }
            }
        }
        contents = WebContents(body: body,
                               remoteContentMode: remoteContentPolicy,
                               renderStyle: currentMessageRenderStyle,
                               supplementCSS: bodyParts?.darkModeCSS)
    }
}

// MARK: Attachments
extension MessageInfoProvider {
    // Some sender / email provider will set disposition of inline as attachment
    // To make sure get correct inlines, needs to check with decrypted body
    private func inlineImages(in decryptedBody: String?, attachments: [AttachmentEntity]) -> [AttachmentEntity]? {
        guard let body = decryptedBody else { return nil }
        if let inlines = inlineAttachments { return inlines }
        let result = attachments.filter { attachment in
            guard let contentID = attachment.getContentID() else { return false }
            if body.preg_match("src=\"\(contentID)\"") ||
                body.preg_match("src=\"cid:\(contentID)\"") ||
                body.preg_match("data-embedded-img=\"\(contentID)\"") ||
                body.preg_match("data-src=\"cid:\(contentID)\"") ||
                body.preg_match("proton-src=\"cid:\(contentID)\"") {
                return true
            }
            return false
        }
        return result
    }

    private func downloadEmbedImage(_ message: MessageEntity) {
        guard self.embeddedStatus == .none,
              message.isDetailDownloaded,
              let inlines = inlineAttachments,
              !inlines.isEmpty else {
            return
        }
        self.embeddedStatus = .downloading
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "AttachmentQueue", qos: .userInitiated)
        let stringsQueue = DispatchQueue(label: "StringsQueue")

        for inline in inlines {
            group.enter()
            let work = DispatchWorkItem {
                self.messageService.base64AttachmentData(inline) { based64String in
                    defer { group.leave() }
                    guard !based64String.isEmpty,
                          let contentID = inline.getContentID() else { return }
                    stringsQueue.sync {
                        let value = "src=\"data:\(inline.rawMimeType);base64,\(based64String)\""
                        self.embeddedBase64["src=\"cid:\(contentID)\""] = value
                    }
                }
            }
            queue.async(group: group, execute: work)
        }

        group.notify(queue: .global()) {
            self.embeddedStatus = .finish
            self.showEmbeddedImages()
        }
    }

    private func showEmbeddedImages() {
        self.replacementQueue.addOperation { [weak self] in
            guard
                let self = self,
                self.embeddedStatus == .finish,
                let currentlyDisplayedBodyParts = self.bodyParts
            else {
                return
            }

            var updatedBody = currentlyDisplayedBodyParts.originalBody
            for (cid, base64) in self.embeddedBase64 {
                updatedBody = updatedBody.replacingOccurrences(of: cid, with: base64)
            }
            self.updateBodyParts(with: updatedBody)
            self.updateWebContents()
        }
    }

    private func checkBannerStatus(_ bodyToCheck: String) {
        let isHavingEmbeddedImages = !(inlineAttachments ?? []).isEmpty

        let helper = BannerHelper(embeddedContentPolicy: embeddedContentPolicy,
                                  remoteContentPolicy: remoteContentPolicy,
                                  isHavingEmbeddedImages: isHavingEmbeddedImages)
        helper.calculateBannerStatus(bodyToCheck: bodyToCheck) { [weak self] showRemoteBanner, showEmbeddedBanner in
            self?.shouldShowRemoteBanner = showRemoteBanner
            self?.shouldShowEmbeddedBanner = showEmbeddedBanner
            self?.delegate?.updateBannerStatus()
        }
    }
}
