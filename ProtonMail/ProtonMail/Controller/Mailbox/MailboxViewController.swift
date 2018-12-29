//
//  MailboxViewController.swift
//  ProtonMail - Created on 8/16/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import CoreData
import MCSwipeTableViewCell

class MailboxViewController: ProtonMailViewController, ViewModelProtocol, CoordinatedNew {
    typealias viewModelType = MailboxViewModel
    typealias coordinatorType = MailboxCoordinator

    private var viewModel: MailboxViewModel!
    private var coordinator: MailboxCoordinator?
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    func set(coordinator: MailboxCoordinator) {
        self.coordinator = coordinator
    }
    
    func set(viewModel: MailboxViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Private constants
    private let kMailboxCellHeight: CGFloat           = 62.0 // change it to auto height
    private let kMailboxRateReviewCellHeight: CGFloat = 125.0
    private let kLongPressDuration: CFTimeInterval    = 0.60 // seconds
    private let kMoreOptionsViewHeight: CGFloat       = 123.0
    
    private let kUndoHidePosition: CGFloat = -100.0
    private let kUndoShowPosition: CGFloat = 44
    
    /// The undo related UI. //TODO:: should move to a custom view to handle it.
    @IBOutlet weak var undoView: UIView!
    @IBOutlet weak var undoLabel: UILabel!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var undoButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var undoBottomDistance: NSLayoutConstraint!
    
    /// no result label
    @IBOutlet weak var noResultLabel: UILabel!
    
    // MARK: TopMessage
    private weak var topMessageView: TopMessageView?
    
    // MARK: - Private attributes
    private var messageID: String? // this is for when user click the notification email
    private var listEditing: Bool = false
    private var timer : Timer!
    private var timerAutoDismiss : Timer?
    
    private var fetchingNewer : Bool = false
    private var fetchingOlder : Bool = false
    private var indexPathForSelectedRow : IndexPath!
    
    private var undoMessage : UndoMessage?
    
    private var isShowUndo : Bool = false
    private var isCheckingHuman: Bool = false
    
    private var fetchingMessage : Bool! = false
    private var fetchingStopped : Bool! = true
    private var needToShowNewMessage : Bool = false
    private var newMessageCount = 0
    
    // MAKR : - Private views
    private var refreshControl: UIRefreshControl!
    private var navigationTitleLabel = UILabel()
    
    // MARK: - Right bar buttons
    
    private var composeBarButtonItem: UIBarButtonItem!
    private var searchBarButtonItem: UIBarButtonItem!
    private var removeBarButtonItem: UIBarButtonItem!
    private var labelBarButtonItem: UIBarButtonItem!
    private var folderBarButtonItem: UIBarButtonItem!
    private var unreadBarButtonItem: UIBarButtonItem!
    private var moreBarButtonItem: UIBarButtonItem!
    
    // MARK: - Left bar button
    
    private var cancelBarButtonItem: UIBarButtonItem!
    private var menuBarButtonItem: UIBarButtonItem!
    
    // MARK: swipactions
    
    private var leftSwipeAction : MessageSwipeAction  = .archive
    private var rightSwipeAction : MessageSwipeAction = .trash
    
    
    
    ///
    var selectedIDs: NSMutableSet = NSMutableSet()

    ///
    func inactiveViewModel() {
        self.viewModel.resetFetchedController()
    }
    
    deinit {
        self.inactiveViewModel()
    }
    
    @objc func doEnterForeground() {
        if viewModel.reloadTable() {
            resetTableView()
        }
    }
    
    func resetTableView() {
        self.viewModel.resetFetchedController()
        self.viewModel.setupFetchController(self)
        self.tableView.reloadData()
    }
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(self.viewModel != nil)
        assert(self.coordinator != nil)

        ///
        self.viewModel.setupFetchController(self)
        
        self.noResultLabel.text = LocalString._messages_no_messages
        self.undoButton.setTitle(LocalString._messages_undo_action, for: .normal)
        self.setNavigationTitleText(viewModel.localizedNavigationTitle)
        self.tableView.RegisterCell(MailboxMessageCell.Constant.identifier)
        self.tableView.RegisterCell(MailboxRateReviewCell.Constant.identifier)
        
        self.addSubViews()

        self.updateNavigationController(listEditing)
        
        if !userCachedStatus.isTourOk() {
            userCachedStatus.resetTourValue()
            self.coordinator?.go(to: .onboarding)
        }
        
        self.undoBottomDistance.constant = self.kUndoHidePosition
        self.undoButton.isHidden = true
        self.undoView.isHidden = true
        
        ///set default swipe action
        self.leftSwipeAction = sharedUserDataService.swiftLeft
        self.rightSwipeAction = sharedUserDataService.swiftRight
        
        ///
        self.viewModel.cleanReviewItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideTopMessage()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChanged(_:)),
                                               name: NSNotification.Name.reachabilityChanged,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(doEnterForeground),
                                               name:  UIApplication.willEnterForegroundNotification,
                                               object: nil)
        self.refreshControl.endRefreshing()
    }
    
    @IBAction func undoAction(_ sender: UIButton) {
        self.undoTheMessage();
        self.hideUndoView();
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.stopAutoFetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.viewModel.processCachedPush()
        
        let usedStorageSpace = sharedUserDataService.usedSpace
        let maxStorageSpace = sharedUserDataService.maxSpace
        StorageLimit().checkSpace(usedStorageSpace, maxSpace: maxStorageSpace)
        
        self.updateInterfaceWithReachability(sharedInternetReachability)
        
        let selectedItem: IndexPath? = self.tableView.indexPathForSelectedRow as IndexPath?
        if let selectedItem = selectedItem {
            self.tableView.reloadRows(at: [selectedItem], with: UITableView.RowAnimation.fade)
            self.tableView.deselectRow(at: selectedItem, animated: true)
        }
        self.startAutoFetch()
        
        FileManager.default.cleanCachedAtts()
        
        if self.viewModel.notificationMessageID != nil {
            self.coordinator?.go(to: .detailsFromNotify)
        } else {
            checkHuman()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    private func addSubViews() {
        self.navigationTitleLabel.backgroundColor = UIColor.clear
        self.navigationTitleLabel.font = Fonts.h2.regular
        self.navigationTitleLabel.textAlignment = NSTextAlignment.center
        self.navigationTitleLabel.textColor = UIColor.white
        self.navigationTitleLabel.text = self.title ?? LocalString._locations_inbox_title
        self.navigationTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationTitleLabel
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        self.refreshControl.addTarget(self, action: #selector(getLatestMessages), for: UIControl.Event.valueChanged)
        self.refreshControl.tintColor = UIColor.gray
        self.refreshControl.tintColorDidChange()
        
        self.tableView.addSubview(self.refreshControl)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.noSeparatorsBelowFooter()
        
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
        
        self.menuBarButtonItem = self.navigationItem.leftBarButtonItem
    }
    
    // MARK: - Public methods
    func setNavigationTitleText(_ text: String?) {
        let animation = CATransition()
        animation.duration = 0.25
        animation.type = CATransitionType.fade
        self.navigationController?.navigationBar.layer.add(animation, forKey: "fadeText")
        if let t = text, t.count > 0 {
            self.title = t
            self.navigationTitleLabel.text = t
        } else {
            self.title = ""
            self.navigationTitleLabel.text = ""
        }
    }
    
    // MARK: - Button Targets
    @objc internal func composeButtonTapped() {
        if checkHuman() {
            self.coordinator?.go(to: .composer)
        }
    }
    @objc internal func searchButtonTapped() {
        self.coordinator?.go(to: .search)
    }
    @objc internal func labelButtonTapped() {
        self.coordinator?.go(to: .labels, sender: self.viewModel.selectedMessages(selected: self.selectedIDs))
    }
    
    @objc internal func folderButtonTapped() {
        self.coordinator?.go(to: .folder, sender: self.viewModel.selectedMessages(selected: self.selectedIDs))
    }
    
    //TODO:: this is a global message should move it to the
    func performSegueForMessageFromNotification() {
        self.coordinator?.go(to: .detailsFromNotify)
    }

    /// unread tapped, this is the button in navigation bar 
    @objc internal func unreadTapped() {
        self.viewModel.mark(IDs: self.selectedIDs, unread: true)
        cancelButtonTapped();
    }
    
    /// remove button tapped. in the navigation bar
    @objc internal func removeButtonTapped() {
        if viewModel.isDelete() {
            moveMessages(to: .trash)
            showMessageMoved(title: LocalString._messages_has_been_deleted)
        } else {
            moveMessages(to: .trash)
            showMessageMoved(title: LocalString._messages_has_been_moved)
        }
        self.cancelButtonTapped();
    }

    @objc internal func moreButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        
        if viewModel.isShowEmptyFolder() {
            let locations: [Message.Location : UIAlertAction.Style] = [.inbox : .default]
            for (location, style) in locations {
                if !viewModel.isCurrentLocation(location) {
                    alertController.addAction(UIAlertAction(title: location.actionTitle, style: style, handler: { (action) -> Void in
                        self.moveMessages(to: location)
                        self.cancelButtonTapped();
                    }))
                }
            }
            
            alertController.addAction(UIAlertAction(title: LocalString._empty_folder,
                                                    style: .destructive, handler: { (action) -> Void in
                self.viewModel.emptyFolder()
                self.showNoResultLabel()
            }))
        } else {
            
            alertController.addAction(UIAlertAction(title: LocalString._mark_read,
                                                    style: .default, handler: { (action) -> Void in
                self.viewModel.mark(IDs: self.selectedIDs, unread: false)
                self.cancelButtonTapped()
            }))
            
            alertController.addAction(UIAlertAction(title: LocalString._locations_add_star_action,
                                                    style: .default, handler: { (action) -> Void in
                self.viewModel.label(IDs: self.selectedIDs, with: Message.Location.starred.rawValue, apply: true)
                self.cancelButtonTapped()
            }))
            
            alertController.addAction(UIAlertAction(title: LocalString._remove_star,
                                                    style: .default, handler: { (action) -> Void in
                self.viewModel.label(IDs: self.selectedIDs, with: Message.Location.starred.rawValue, apply: false)
                self.cancelButtonTapped()
            }))
            
            var locations: [Message.Location : UIAlertAction.Style] = [.inbox : .default, .spam : .default, .archive : .default]
            if !viewModel.isCurrentLocation(.sent) {
                locations = [.spam : .default, .archive : .default]
            }
            
            if viewModel.isCurrentLocation(.archive) || viewModel.isCurrentLocation(.trash) || viewModel.isCurrentLocation(.spam) {
                locations[.inbox] = .default
            }

            if (viewModel.isCurrentLocation(.sent)) {
                locations = [:];
            }

            for (location, style) in locations {
                if !viewModel.isCurrentLocation(location) {
                    alertController.addAction(UIAlertAction(title: location.actionTitle, style: style, handler: { (action) -> Void in
                        self.moveMessages(to: location)
                        self.cancelButtonTapped()
                        self.navigationController?.popViewController(animated: true)
                    }))
                }
            }
        }
        
        alertController.popoverPresentationController?.barButtonItem = moreBarButtonItem
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        present(alertController, animated: true, completion: nil)
    }
    
    @objc internal func cancelButtonTapped() {
        self.selectedIDs.removeAllObjects()
        self.hideCheckOptions()
        self.updateNavigationController(false)
    }
    
    @objc internal func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        self.showCheckOptions(longPressGestureRecognizer)
        updateNavigationController(listEditing)
    }

    internal func beginRefreshingManually(animated: Bool) {
        if animated {
            self.refreshControl.beginRefreshing()
            if (self.tableView.contentOffset.y == 0) {
                UIView.animate(withDuration: 0.25, animations: {
                    self.tableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height);
                })
            }
        }
    }
    
    // MARK: - Private methods
    private func startAutoFetch(_ run : Bool = true) {
        self.timer = Timer.scheduledTimer(timeInterval: self.timerInterval,
                                          target: self,
                                          selector: #selector(refreshPage),
                                          userInfo: nil,
                                          repeats: true)
        fetchingStopped = false
        if run {
            self.timer.fire()
        }
    }
    
    private func stopAutoFetch() {
        fetchingStopped = true
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    @objc func refreshPage() {
        if !fetchingStopped {
            self.getLatestMessages()
        }
    }
    
    private func checkContact() {
        sharedContactDataService.fetchContacts { (_, _) in

        }
    }
    
    @discardableResult
    private func checkHuman() -> Bool {
        if sharedMessageQueue.isRequiredHumanCheck && isCheckingHuman == false {
            //show human check view with warning
            isCheckingHuman = true
            self.coordinator?.go(to: .humanCheck)
            return false
        }
        return true
    }
    
    fileprivate var timerInterval : TimeInterval = 30
    fileprivate var failedTimes = 30
    
    func offlineTimerReset() {
        timerInterval = TimeInterval(arc4random_uniform(90)) + 30;
        stopAutoFetch()
        startAutoFetch(false)
    }
    
    func onlineTimerReset() {
        timerInterval = 30
        stopAutoFetch()
        startAutoFetch(false)
    }
    
    private func configure(cell inputCell: UITableViewCell?, indexPath: IndexPath) {
        guard let mailboxCell = inputCell as? MailboxMessageCell else {
            return
        }
        guard let message = self.viewModel.item(index: indexPath) else {
            return
        }
        mailboxCell.configureCell(message, showLocation: viewModel.showLocation(), ignoredTitle: viewModel.ignoredLocationTitle())
        mailboxCell.setCellIsChecked(self.selectedIDs.contains(message.messageID))
        if (self.listEditing) {
            mailboxCell.showCheckboxOnLeftSide()
        } else {
            mailboxCell.hideCheckboxOnLeftSide()
        }
        mailboxCell.zeroMargin()
        mailboxCell.defaultColor = UIColor.lightGray
        let leftCrossView = UILabel();
        leftCrossView.text = self.viewModel.getSwipeTitle(leftSwipeAction)
        leftCrossView.sizeToFit()
        leftCrossView.textColor = UIColor.white
        
        let rightCrossView = UILabel();
        rightCrossView.text = self.viewModel.getSwipeTitle(rightSwipeAction)
        rightCrossView.sizeToFit()
        rightCrossView.textColor = UIColor.white
        
        if self.viewModel.isSwipeActionValid(self.leftSwipeAction) {
            mailboxCell.setSwipeGestureWith(leftCrossView, color: leftSwipeAction.actionColor, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state1 ) { [weak self] (cell, state, mode) -> Void in
                guard let `self` = self else { return }
                guard let cell = cell else { return }
                if let indexp = self.tableView.indexPath(for: cell) {
                    if self.viewModel.isSwipeActionValid(self.leftSwipeAction) {
                        if !self.processSwipeActions(self.leftSwipeAction, indexPath: indexp) {
                            mailboxCell.swipeToOrigin(completion: nil)
                        } else if self.viewModel.stayAfterAction(self.leftSwipeAction) {
                            mailboxCell.swipeToOrigin(completion: nil)
                        }
                    } else {
                        mailboxCell.swipeToOrigin(completion: nil)
                    }
                } else {
                    self.tableView.reloadData()
                }
            }
        }
        
        if self.viewModel.isSwipeActionValid(self.rightSwipeAction) {
            mailboxCell.setSwipeGestureWith(rightCrossView, color: rightSwipeAction.actionColor, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state3  ) { [weak self] (cell, state, mode) -> Void in
                guard let `self` = self else { return }
                guard let cell = cell else { return }
                if let indexp = self.tableView.indexPath(for: cell) {
                    if self.viewModel.isSwipeActionValid(self.rightSwipeAction) {
                        if !self.processSwipeActions(self.rightSwipeAction, indexPath: indexp) {
                            mailboxCell.swipeToOrigin(completion: nil)
                        } else if self.viewModel.stayAfterAction(self.rightSwipeAction) {
                            mailboxCell.swipeToOrigin(completion: nil)
                        }
                    } else {
                        mailboxCell.swipeToOrigin(completion: nil)
                    }
                } else {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func processSwipeActions(_ action: MessageSwipeAction, indexPath: IndexPath) -> Bool {
        ///UIAccessibility
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: action.description)
        switch (action) {
        case .archive:
            self.archive(indexPath)
            return true
        case .trash:
            self.delete(indexPath)
            return true
        case .spam:
            self.spam(indexPath)
            return true
        case .star:
            self.star(indexPath)
            return false
        case .unread:
            self.unread(indexPath)
            return false
        }
    }
    
    private func archive(_ index: IndexPath) {
        let (res, undo) = self.viewModel.archive(index: index)
        switch res {
        case .showUndo:
            undoMessage = undo
            showUndoView(LocalString._messages_archived)
        case .showGeneral:
            showMessageMoved(title: LocalString._messages_has_been_moved)
        default: break
        }
    }
    private func delete(_ index: IndexPath) {
        let (res, undo) = self.viewModel.delete(index: index)
        switch res {
        case .showUndo:
            undoMessage = undo
            showUndoView(LocalString._locations_deleted_desc)
        case .showGeneral:
            showMessageMoved(title: LocalString._messages_has_been_deleted)
        default: break
        }
    }
    
    private func spam(_ index: IndexPath) {
        let (res, undo) = self.viewModel.spam(index: index)
        switch res {
        case .showUndo:
            undoMessage = undo
            showUndoView(LocalString._messages_spammed)
        case .showGeneral:
            showMessageMoved(title: LocalString._messages_has_been_moved)
        default: break
            
        }
    }
    
    private func star(_ indexPath: IndexPath) {
        if let message = self.viewModel.item(index: indexPath) {
            self.viewModel.label(msg: message, with: Message.Location.starred.rawValue)
        }
    }
    
    private func unread(_ indexPath: IndexPath) {
        if let message = self.viewModel.item(index: indexPath) {
           self.viewModel.mark(msg: message)
        }
    }
    
    fileprivate func undoTheMessage() { //need move into viewModel
        if let undoMsg = undoMessage {
            self.viewModel.undo(undoMsg)
            undoMessage = nil
        }
    }
    
    fileprivate func showUndoView(_ title : String) {
        undoLabel.text = String(format: LocalString._messages_with_title, title)
        self.undoBottomDistance.constant = self.kUndoShowPosition
        self.undoButton.isHidden = false
        self.undoView.isHidden = false
        self.undoButtonWidth.constant = 100.0
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.timerAutoDismiss = Timer.scheduledTimer(timeInterval: 3,
                                                     target: self,
                                                     selector: #selector(MailboxViewController.timerTriggered),
                                                     userInfo: nil,
                                                     repeats: false)
    }
    
    fileprivate func showMessageMoved(title : String) {
        undoLabel.text = title
        self.undoBottomDistance.constant = self.kUndoShowPosition
        self.undoButton.isHidden = false
        self.undoView.isHidden = false
        self.undoButtonWidth.constant = 0.0
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.timerAutoDismiss = Timer.scheduledTimer(timeInterval: 3,
                                                     target: self,
                                                     selector: #selector(MailboxViewController.timerTriggered),
                                                     userInfo: nil,
                                                     repeats: false)
    }
    
    fileprivate func hideUndoView() {
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.undoBottomDistance.constant = self.kUndoHidePosition
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            self.undoButton.isHidden = true
            self.undoView.isHidden = true
        }
    }
    
    @objc func timerTriggered() {
        self.hideUndoView()
    }
  
    
    fileprivate func checkEmptyMailbox () {
        guard self.fetchingStopped == true else {
            return
        }
        guard self.viewModel.sectionCount() > 0 else {
            return
        }
        let rowCount = self.viewModel.rowCount(section: 0)
        guard rowCount == 0 else {
            return
        }
        let updateTime = viewModel.lastUpdateTime()
        let recordedCount = Int(updateTime.total)
        if updateTime.isNew || recordedCount > rowCount {
            self.fetchingOlder = true
            viewModel.fetchMessages(time: 0, foucsClean: false, completion: { (task, messages, error) -> Void in
                self.fetchingOlder = false
                if error != nil {
                    PMLog.D("search error: \(String(describing: error))")
                }
                self.checkHuman()
            })
        }
    }
    
    func handleRequestError (_ error : NSError) {
        let code = error.code
        if code == NSURLErrorTimedOut {
            self.showTimeOutErrorMessage()
        } else if code == NSURLErrorNotConnectedToInternet || code == NSURLErrorCannotConnectToHost {
            self.showNoInternetErrorMessage()
        } else if code == APIErrorCode.API_offline {
            self.showOfflineErrorMessage(error)
            offlineTimerReset()
        } else if code == APIErrorCode.HTTP503 || code == NSURLErrorBadServerResponse {
            self.show503ErrorMessage(error)
            offlineTimerReset()
        } else if code == APIErrorCode.HTTP504 {
            self.showTimeOutErrorMessage()
        }
        PMLog.D("error: \(error)")
    }
    
    @objc internal func getLatestMessages() {
        self.hideTopMessage()
        if !fetchingMessage {
            fetchingMessage = true
            
            self.beginRefreshingManually(animated: self.viewModel.rowCount(section: 0) < 1 ? true : false)
            let updateTime = viewModel.lastUpdateTime()
            let complete : APIService.CompletionBlock = { (task, res, error) -> Void in
                self.needToShowNewMessage = false
                self.newMessageCount = 0
                self.fetchingMessage = false
                
                if self.fetchingStopped! == true {
                    return;
                }
                
                if let error = error {
                    self.handleRequestError(error)
                }
                
                var loadMore: Int = 0
                if error == nil {
                    self.onlineTimerReset()
                    self.viewModel.resetNotificationMessage()
                    if !updateTime.isNew {
                        
                    }
                    if let notices = res?["Notices"] as? [String] {
                        serverNotice.check(notices)
                    }
                    
                    if let more = res?["More"] as? Int {
                       loadMore = more
                    }
                    
                    if loadMore <= 0 {
                        sharedMessageDataService.updateMessageCount()
                    }
                }
                
                if loadMore > 0 {
                     self.retry()
                } else {
                    self.refreshControl.endRefreshing()
                    if self.fetchingStopped! == true {
                        return;
                    }
                    self.showNoResultLabel()
                    let _ = self.checkHuman()
                    
                    UIView.animate(withDuration: 0.25, animations: {
                        self.tableView.contentOffset = CGPoint(x: 0, y: 0);
                    })
                }
                
            }
            
            if (updateTime.isNew) {
                if lastUpdatedStore.lastEventID == "0" {
                    viewModel.fetchMessageWithReset(time: 0, completion: complete)
                }
                else {
                    viewModel.fetchMessages(time: 0, foucsClean: false, completion: complete)
                }
            } else {
                //fetch
                self.needToShowNewMessage = true
                viewModel.fetchEvents(time: Int(updateTime.start.timeIntervalSince1970),
                                      notificationMessageID: self.viewModel.notificationMessageID,
                                      completion: complete)
                self.checkEmptyMailbox()
            }
            
            self.checkContact()
        }
    }
    
    fileprivate func showNoResultLabel() {
        let count =  self.viewModel.sectionCount() > 0 ? self.viewModel.rowCount(section: 0) : 0
        if (count <= 0 && !fetchingMessage ) {
            self.noResultLabel.isHidden = false;
        } else {
            self.noResultLabel.isHidden = true;
        }
    }

    internal func moveMessages(to location: Message.Location) {
        self.viewModel.move(IDs: self.selectedIDs, to: location.rawValue)
    }
    
    internal func tappedMassage(_ message: Message) {
        guard viewModel.isDrafts() || message.draft else {
            self.coordinator?.go(to: .details)
            self.tableView.indexPathsForSelectedRows?.forEach {
                self.tableView.deselectRow(at: $0, animated: true)
            }
            return
        }

        guard !message.messageID.isEmpty else {
            if self.checkHuman() {
                //TODO::QA
                self.coordinator?.go(to: .composeShow)
            }
            return
        }
        
        sharedMessageDataService.ForcefetchDetailForMessage(message) {_, _, msg, error in
            guard let objectId = msg?.objectID,
                let message = self.viewModel.object(by: objectId),
                message.body.isEmpty == false else
            {
                if error != nil {
                    PMLog.D("error: \(String(describing: error))")
                    let alert = LocalString._unable_to_edit_offline.alertController()
                    alert.addOKAction()
                    self.present(alert, animated: true, completion: nil)
                    self.tableView.indexPathsForSelectedRows?.forEach {
                        self.tableView.deselectRow(at: $0, animated: true)
                    }
                }
                return
            }
            if self.checkHuman() {
                self.coordinator?.go(to: .composeShow, sender: message)
            }
        }
    }
    
    fileprivate func selectMessageIDIfNeeded() {
        if let msgID = messageID {
            if let message = self.viewModel.message(by: msgID) {
                self.tappedMassage(message)
            }
        }
        self.messageID = nil
    }
    

    fileprivate func setupLeftButtons(_ editingMode: Bool) {
        var leftButtons: [UIBarButtonItem]
        
        if (!editingMode) {
            leftButtons = [self.menuBarButtonItem]
        } else {
            if (self.cancelBarButtonItem == nil) {
                self.cancelBarButtonItem = UIBarButtonItem(title: LocalString._general_cancel_button,
                                                           style: UIBarButtonItem.Style.plain,
                                                           target: self,
                                                           action: #selector(cancelButtonTapped))
            }
            
            leftButtons = [self.cancelBarButtonItem]
        }
        
        self.navigationItem.setLeftBarButtonItems(leftButtons, animated: true)
    }
    
    private func setupNavigationTitle(_ editingMode: Bool) {
        if (editingMode) {
            self.setNavigationTitleText("")
        } else {
            self.setNavigationTitleText(viewModel.localizedNavigationTitle)
        }
    }
    
    private func BarItem(image: UIImage?, action: Selector? ) -> UIBarButtonItem {
       return  UIBarButtonItem(image: image, style: UIBarButtonItem.Style.plain, target: self, action: action)
    }
    
    private func setupRightButtons(_ editingMode: Bool) {
        var rightButtons: [UIBarButtonItem]
        
        if (!editingMode) {
            if (self.composeBarButtonItem == nil) {
                self.composeBarButtonItem = BarItem(image: UIImage.Top.compose, action: #selector(composeButtonTapped))
            }
            
            if (self.searchBarButtonItem == nil) {
                self.searchBarButtonItem = BarItem(image: UIImage.Top.search, action: #selector(searchButtonTapped))
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = BarItem(image: UIImage.Top.more, action: #selector(moreButtonTapped))
            }
            
            if viewModel.isShowEmptyFolder() {
                rightButtons = [self.moreBarButtonItem, self.composeBarButtonItem, self.searchBarButtonItem]
            } else {
                rightButtons = [self.composeBarButtonItem, self.searchBarButtonItem]
            }
        } else {
            if (self.unreadBarButtonItem == nil) {
                self.unreadBarButtonItem = BarItem(image: UIImage.Top.unread, action: #selector(unreadTapped))
            }
            
            if (self.labelBarButtonItem == nil) {
                self.labelBarButtonItem = BarItem(image: UIImage.Top.label, action: #selector(labelButtonTapped))
            }
            
            if (self.folderBarButtonItem == nil) {
                self.folderBarButtonItem = BarItem(image: UIImage.Top.folder, action: #selector(folderButtonTapped))
            }
            
            if (self.removeBarButtonItem == nil) {
                self.removeBarButtonItem = BarItem(image: UIImage.Top.trash, action: #selector(removeButtonTapped))
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = BarItem(image: UIImage.Top.more, action: #selector(moreButtonTapped))
            }
            
            if (viewModel.isDrafts()) {
                rightButtons = [self.removeBarButtonItem]
            } else if (viewModel.isCurrentLocation(.sent)) {
                rightButtons = [self.moreBarButtonItem, self.removeBarButtonItem, self.labelBarButtonItem, self.unreadBarButtonItem]
            } else {
                rightButtons = [self.moreBarButtonItem, self.removeBarButtonItem, self.folderBarButtonItem, self.labelBarButtonItem, self.unreadBarButtonItem]
            }
        }
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    
    fileprivate func hideCheckOptions() {
        self.listEditing = false
        if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
            for indexPath in indexPathsForVisibleRows {
                if let messageCell: MailboxMessageCell = self.tableView.cellForRow(at: indexPath) as? MailboxMessageCell {
                    messageCell.setCellIsChecked(false)
                    messageCell.hideCheckboxOnLeftSide()
                    UIView.animate(withDuration: 0.25, animations: { () -> Void in
                        messageCell.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    fileprivate func showCheckOptions(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let point: CGPoint = longPressGestureRecognizer.location(in: self.tableView)
        let indexPath: IndexPath? = self.tableView.indexPathForRow(at: point)
        
        if let indexPath = indexPath {
            if (longPressGestureRecognizer.state == UIGestureRecognizer.State.began) {
                self.listEditing = true
                if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
                    for visibleIndexPath in indexPathsForVisibleRows {
                        if let messageCell: MailboxMessageCell = self.tableView.cellForRow(at: visibleIndexPath) as? MailboxMessageCell {
                            messageCell.showCheckboxOnLeftSide()
                            // set selected row to checked
                            if (indexPath.row == visibleIndexPath.row) {
                                if let message = self.viewModel.item(index: indexPath) {
                                    self.selectedIDs.add(message.messageID)
                                }
                                messageCell.setCellIsChecked(true)
                            }
                            
                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                                messageCell.layoutIfNeeded()
                            })
                        }
                    }
                }
                PMLog.D("Long press on table view at row \(indexPath.row)")
            }
        } else {
            PMLog.D("Long press on table view, but not on a row.")
        }
    }
    
    fileprivate func updateNavigationController(_ editingMode: Bool) {
        self.setupLeftButtons(editingMode)
        self.setupNavigationTitle(editingMode)
        self.setupRightButtons(editingMode)
    }
 
}

extension MailboxViewController : LablesViewControllerDelegate {
    func dismissed() {
        
    }
    
    func apply(type: LabelFetchType) {
        if type == .label {
            showMessageMoved(title: LocalString._messages_labels_applied)
        } else if type == .folder {
            showMessageMoved(title: LocalString._messages_has_been_moved)
        }
    }
}

extension MailboxViewController : MailboxCaptchaVCDelegate {
    
    func cancel() {
        isCheckingHuman = false
    }
    
    func done() {
        isCheckingHuman = false
        sharedMessageQueue.isRequiredHumanCheck = false
    }
}

extension MailboxViewController : TopMessageViewDelegate {
    
    private func showBanner(_ message: String,
                            appearance: TopMessageView.Appearance,
                            buttons: Set<TopMessageView.Buttons> = [])
    {
        if let oldMessageView = self.topMessageView {
            oldMessageView.remove(animated: true)
        }
        
        let newMessageView = TopMessageView(appearance: appearance,
                                            message: message,
                                            buttons: buttons,
                                            lowerPoint: self.navigationController!.navigationBar.frame.size.height + self.self.navigationController!.navigationBar.frame.origin.y + 8.0)
        newMessageView.delegate = self
        if let superview = self.navigationController?.view {
            self.topMessageView = newMessageView
            superview.insertSubview(newMessageView, belowSubview: self.navigationController!.navigationBar)
            newMessageView.showAnimation(withSuperView: superview)
        }
    }
    
    internal func showErrorMessage(_ error: NSError?) {
        guard let error = error else { return }
        showBanner(error.localizedDescription, appearance: .red)
    }
    
    internal func showTimeOutErrorMessage() {
        showBanner(LocalString._general_request_timed_out, appearance: .red, buttons: [.close])
    }
    
    internal func showNoInternetErrorMessage() {
        showBanner(LocalString._general_no_connectivity_detected, appearance: .red, buttons: [.close])
    }
    
    internal func showOfflineErrorMessage(_ error : NSError?) {
        showBanner(error?.localizedDescription ?? LocalString._general_pm_offline, appearance: .red, buttons: [.close])
    }
    
    internal func show503ErrorMessage(_ error : NSError?) {
        showBanner(LocalString._general_api_server_not_reachable, appearance: .red, buttons: [.close])
    }
    
    
    internal func showNewMessageCount(_ count : Int) {
        guard self.needToShowNewMessage, count > 0 else { return }
        self.needToShowNewMessage = false
        self.newMessageCount = 0
        let message = count == 1 ? LocalString._messages_you_have_new_email : String(format: LocalString._messages_you_have_new_emails_with, count)
        message.alertToastBottom()
    }
    
    @objc internal func reachabilityChanged(_ note : Notification) {
        if let curReach = note.object as? Reachability {
            self.updateInterfaceWithReachability(curReach)
        } else {
            if let status = note.object as? Int {
                PMLog.D("\(status)")
                if status == 0 { //time out
                    showTimeOutErrorMessage()
                } else if status == 1 { //not reachable
                    showNoInternetErrorMessage()
                }
            }
        }
    }
    
    internal func updateInterfaceWithReachability(_ reachability : Reachability) {
        let netStatus = reachability.currentReachabilityStatus()
        switch (netStatus){
        case .NotReachable:
            PMLog.D("Access Not Available")
            self.showNoInternetErrorMessage()
            
        case .ReachableViaWWAN:
            PMLog.D("Reachable WWAN")
            self.hideTopMessage()

        case .ReachableViaWiFi:
            PMLog.D("Reachable WiFi")
            self.hideTopMessage()

        default:
            PMLog.D("Reachable default unknow")
        }
    }
    
    func hideTopMessage() {
        self.topMessageView?.remove(animated: true)
    }
    
    func retry() {
        self.getLatestMessages()
    }
}

extension MailboxViewController : FeedbackPopViewControllerDelegate {
    func cancelled() {
        // just cancelled
    }
    
    func showHelp() {
        self.coordinator?.go(to: .feedbackView)
    }
    
    func showSupport() {
        self.coordinator?.go(to: .feedbackView)
    }
    
    func showRating() {
        self.coordinator?.go(to: .feedbackView)
    }
}

// MARK : review delegate
extension MailboxViewController: MailboxRateReviewCellDelegate {
    func mailboxRateReviewCell(_ cell: UITableViewCell, yesORno: Bool) {
        self.viewModel.cleanReviewItems()
        // go to next screen
        if yesORno == true {
            //TODO::QA
            self.coordinator?.go(to: .feedback)
        }
    }
}


// MARK: - UITableViewDataSource
extension MailboxViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sectionCount()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.rowCount(section: section)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let rIndex = self.viewModel.ratingIndex {
            if rIndex == indexPath {
                let mailboxRateCell = tableView.dequeueReusableCell(withIdentifier: MailboxRateReviewCell.Constant.identifier, for: rIndex) as! MailboxRateReviewCell
                mailboxRateCell.callback = self
                mailboxRateCell.selectionStyle = .none
                return mailboxRateCell
            }
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: MailboxMessageCell.Constant.identifier, for: indexPath)
        self.configure(cell: cell, indexPath: indexPath)
        return cell

    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension MailboxViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        self.showNewMessageCount(self.newMessageCount)
        selectMessageIDIfNeeded()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch(type) {
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            }
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: UITableView.RowAnimation.fade)
                if self.needToShowNewMessage == true {
                    if let newMsg = anObject as? Message {
                        if let msgTime = newMsg.time, newMsg.unRead {
                            let updateTime = viewModel.lastUpdateTime()
                            if msgTime.compare(updateTime.start as Date) != ComparisonResult.orderedAscending {
                                self.newMessageCount += 1
                            }
                        }
                    }
                }
            }
        case .update:
            if let indexPath = indexPath {
                let cell = tableView.cellForRow(at: indexPath)
                self.configure(cell: cell, indexPath: indexPath)
            }
        default:
            return
        }
        
        if self.noResultLabel.isHidden == false {
            self.showNoResultLabel()
        }
    }
}


// MARK: - UITableViewDelegate

extension MailboxViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let current = self.viewModel.item(index: indexPath) else {
            return
        }
        let updateTime = viewModel.lastUpdateTime()
        if let currentTime = current.time {
            let isOlderMessage = updateTime.end.compare(currentTime as Date) != ComparisonResult.orderedAscending
            let loadMore = self.viewModel.loadMore(index: indexPath)
            if  (isOlderMessage || loadMore) && !self.fetchingOlder {
                let sectionCount = self.viewModel.rowCount(section: indexPath.section)
                let recordedCount = Int(updateTime.total)
                //here need add a counter to check if tried too many times make one real call in case count not right
                if updateTime.isNew || recordedCount > sectionCount {
                    self.fetchingOlder = true
                    self.tableView.showLoadingFooter()
                    let updateTime = self.viewModel.lastUpdateTime()
                    let unixTimt: Int = (updateTime.end as Date == Date.distantPast ) ? 0 : Int(updateTime.end.timeIntervalSince1970)
                    self.viewModel.fetchMessages(time: unixTimt, foucsClean: false, completion: { (task, response, error) -> Void in
                        self.tableView.hideLoadingFooter()
                        self.fetchingOlder = false
                        self.checkHuman()
                    })
                }
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let rIndex = self.viewModel.ratingIndex {
            if rIndex == indexPath {
                return kMailboxRateReviewCellHeight
            }
        }
        return kMailboxCellHeight

    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let rIndex = self.viewModel.ratingIndex {
            if rIndex == indexPath {
                return nil
            }
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let message = self.viewModel.item(index: indexPath) {
            if (self.listEditing) {
                let messageAlreadySelected: Bool = self.selectedIDs.contains(message.messageID)
                if (messageAlreadySelected) {
                    self.selectedIDs.remove(message.messageID)
                } else {
                    self.selectedIDs.add(message.messageID)
                }
                // update checkbox state
                if let mailboxCell: MailboxMessageCell = tableView.cellForRow(at: indexPath) as? MailboxMessageCell {
                    mailboxCell.setCellIsChecked(!messageAlreadySelected)
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
            } else {
                self.indexPathForSelectedRow = indexPath
                self.tappedMassage(message)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let frame = noResultLabel.frame;
        if scrollView.contentOffset.y <= 0 {
            self.noResultLabel.frame = CGRect(x: frame.origin.x, y: -scrollView.contentOffset.y, width: frame.width, height: frame.height);
        } else {
            self.noResultLabel.frame = CGRect(x: frame.origin.x, y: 0, width: frame.width, height: frame.height);
        }
    }
}
