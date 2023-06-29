// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCore_Networking
import ProtonCore_Services

final class DownloadPageOperation: AsyncOperation {

    private let apiService: APIService
    private let endTime: Int?
    private let beginTime: Int?
    private let labelID: LabelID
    private let pageSize: Int
    private let userID: UserID
    private(set) var result: Result<[MessageID], Error>?

    init(
        apiService: APIService,
        endTime: Int?,
        beginTime: Int?,
        labelID: LabelID,
        pageSize: Int,
        userID: UserID
    ) {
        self.apiService = apiService
        self.endTime = endTime
        self.beginTime = beginTime
        self.labelID = labelID
        self.pageSize = pageSize
        self.userID = userID
    }

    override func main() {
        super.main()

        let request = FetchMessagesByLabelRequest(
            labelID: labelID.rawValue,
            endTime: endTime,
            beginTime: beginTime,
            isUnread: false,
            pageSize: pageSize,
            priority: .lowestPriority
        )
        if isCancelled { return }

        apiService.perform(request: request) { [weak self] _, result in
            defer { self?.finish() }
            guard let self = self, !self.isCancelled else { return }
            switch result {
            case .failure(let error):
                self.log(message: "Download page operation failed \(error)", isError: true)
                self.result = .failure(error)
            case .success(let dict):
                self.result = self.parseDownloadMessagePage(response: dict)
            }
        }
    }

    private func parseDownloadMessagePage(response dict: JSONDictionary) -> Result<[MessageID], Error> {
        var timeInfo: String = "No time information"
        if let beginTime {
            timeInfo = "beginTime \(beginTime)"
        } else if let endTime {
            timeInfo = "endTime \(endTime)"
        }
        guard let messagesArray = dict["Messages"] as? [[String: Any]] else {
            log(message: "Parse message list (\(timeInfo)) response failed, due to no Messages in dictionary")
            return .failure(NSError.unableToParseResponse(dict))
        }
        let messageIDs = messagesArray.compactMap { data -> MessageID? in
            guard let id = data["ID"] as? String else { return nil }
            return MessageID(id)
        }
        log(message: "Parse message list (\(timeInfo)) success, messages count \(messageIDs.count)")
        return .success(messageIDs)
    }
}
