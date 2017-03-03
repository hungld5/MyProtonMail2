//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit
import CoreData

class MenuViewController: UIViewController {
    internal static let ObserverSwitchView:String = "Push_Switch_View"
    
    // MARK - Views Outlets
    
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerView: UIView!
    
    // MARK: - Private constants
    
    private let inboxItems : [MenuItem] = [.inbox, .drafts, .sent, .starred, .archive, .spam, .trash, .allmail]
    private var otherItems : [MenuItem] = [.contacts, .settings, .bugs, /*MenuItem.feedback,*/ .signout]
    private var fetchedLabels: NSFetchedResultsController?
    private var signingOut: Bool = false
    
    private let kMenuCellHeight: CGFloat = 44.0
    private let kMenuOptionsWidth: CGFloat = 300.0 //227.0
    private let kMenuOptionsWidthOffset: CGFloat = 80.0
    
    private let kSegueToMailbox: String = "toMailboxSegue"
    private let kSegueToLabelbox: String = "toLabelboxSegue"
    private let kSegueToSettings: String = "toSettingsSegue"
    private let kSegueToBugs: String = "toBugsSegue"
    private let kSegueToContacts: String = "toContactsSegue"
    private let kSegueToFeedback: String = "toFeedbackSegue"
    private let kMenuTableCellId = "menu_table_cell"
    private let kLabelTableCellId = "menu_label_cell"
    
    // temp vars
    private var lastSegue: String = "toMailboxSegue"
    private var lastMenuItem: MenuItem = MenuItem.inbox
    private var sectionClicked : Bool = false
    
    // private data
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MenuViewController.ObserverSwitchView, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsController()
        
        let w = UIScreen.mainScreen().applicationFrame.width;
        let offset =  (w - kMenuOptionsWidthOffset)
        self.revealViewController().rearViewRevealWidth = kMenuOptionsWidth > offset ? offset : kMenuOptionsWidth
        
        tableView.dataSource = self
        tableView.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(MenuViewController.performLastSegue(_:)),
            name: MenuViewController.ObserverSwitchView,
            object: nil)
        
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
        
        sharedLabelsDataService.fetchLabels();
    }
    
    func performLastSegue(notification: NSNotification)
    {
        self.performSegueWithIdentifier(lastSegue, sender: NSIndexPath(forRow: 0, inSection: 0))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let w = UIScreen.mainScreen().applicationFrame.width;
        let offset =  (w - kMenuOptionsWidthOffset)
        self.revealViewController().rearViewRevealWidth = kMenuOptionsWidth > offset ? offset : kMenuOptionsWidth
        
        self.revealViewController().frontViewController.view.userInteractionEnabled = false
        self.revealViewController().view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        self.sectionClicked = false
        
        if ((userCachedStatus.isPinCodeEnabled && !userCachedStatus.pinCode.isEmpty) || (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled)) {
            otherItems = [.contacts, .settings, .bugs, /*MenuItem.feedback,*/ .lockapp, .signout]
        } else {
            otherItems = [MenuItem.contacts, MenuItem.settings, MenuItem.bugs, /*MenuItem.feedback,*/ MenuItem.signout]
        }
        
        
        updateEmailLabel()
        updateDisplayNameLabel()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.revealViewController().frontViewController.view.userInteractionEnabled = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as! UINavigationController
        if let firstViewController: UIViewController = navigationController.viewControllers.first as UIViewController? {
            if (firstViewController.isKindOfClass(MailboxViewController)) {
                let mailboxViewController: MailboxViewController = navigationController.viewControllers.first as! MailboxViewController
                if let indexPath = sender as? NSIndexPath {
                    PMLog.D("Menu Table Clicked -- Done")
                    if indexPath.section == 0 {
                        self.lastMenuItem = self.itemForIndexPath(indexPath)
                        mailboxViewController.viewModel = MailboxViewModelImpl(location: self.lastMenuItem.menuToLocation)
                    } else if indexPath.section == 1 {
                    } else if indexPath.section == 2 {
                        //if indexPath.row < fetchedLabels?.fetchedObjects?.count {
                        let label = self.fetchedLabels?.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as! Label
                        mailboxViewController.viewModel = LabelboxViewModelImpl(label: label)
                        //}
                    } else {
                    }
                }
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        PMLog.D("Menu Table Clicked -- Checked")
        return true
    }
    
    // MARK: - Methods
    private func setupFetchedResultsController() {
        self.fetchedLabels = sharedLabelsDataService.fetchedResultsController(.all)
        self.fetchedLabels?.delegate = self
        PMLog.D("INFO: \(fetchedLabels?.sections)")
        if let fetchedResultsController = fetchedLabels {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func handleSignOut(sender : UIView?) {
        let alertController = UIAlertController(title: NSLocalizedString("Confirm"), message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Sign Out"), style: .Destructive, handler: { (action) -> Void in
            self.signingOut = true
            UserTempCachedStatus.backup()
            sharedUserDataService.signOut(true)
            userCachedStatus.signOut()
        }))
        alertController.popoverPresentationController?.sourceView = sender ?? self.view
        alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.bounds)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
        self.sectionClicked = false
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func itemForIndexPath(indexPath: NSIndexPath) -> MenuItem {
        return inboxItems[indexPath.row]
    }
    
    func updateDisplayNameLabel() {
        let displayName = sharedUserDataService.defaultDisplayName
        if !displayName.isEmpty {
            displayNameLabel.text = displayName
            return
        }
        displayNameLabel.text = emailLabel.text
    }
    
    func updateEmailLabel() {
        emailLabel.text = sharedUserDataService.defaultEmail;
    }
}

extension MenuViewController: UITableViewDelegate {
    
    func closeMenu() {
        self.revealViewController().revealToggleAnimated(true)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kMenuCellHeight
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if !self.sectionClicked {
            self.sectionClicked = true
        } else {
            return
        }
        
        PMLog.D("Menu Table Clicked")
        if indexPath.section == 0 { //inbox
            self.performSegueWithIdentifier(kSegueToMailbox, sender: indexPath);
        } else if (indexPath.section == 1) {
            //others
            let item = otherItems[indexPath.row]
            if item == .signout {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                let cell = tableView.cellForRowAtIndexPath(indexPath)
                self.handleSignOut(cell)
            } else if item == .settings {
                self.performSegueWithIdentifier(kSegueToSettings, sender: indexPath);
            } else if item == .bugs {
                self.performSegueWithIdentifier(kSegueToBugs, sender: indexPath);
            } else if item == .contacts {
                self.performSegueWithIdentifier(kSegueToContacts, sender: indexPath);
            } else if item == .feedback {
                self.performSegueWithIdentifier(kSegueToFeedback, sender: indexPath);
            } else if item == .lockapp {
                userCachedStatus.lockedApp = true;
                (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .signIn, animated: true)
                sharedVMService.resetComposerView()
            }
        } else if (indexPath.section == 2) {
            //labels
            self.performSegueWithIdentifier(kSegueToLabelbox, sender: indexPath);
        }
    }
}

extension MenuViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return inboxItems.count
        } else if (section == 1) {
            return otherItems.count
        } else if (section == 2) {
            let count = fetchedLabels?.numberOfRowsInSection(0) ?? 0
            return count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(kMenuTableCellId, forIndexPath: indexPath) as! MenuTableViewCell
            cell.configCell(inboxItems[indexPath.row])
            cell.configUnreadCount()
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(kMenuTableCellId, forIndexPath: indexPath) as! MenuTableViewCell
            cell.configCell(otherItems[indexPath.row])
            cell.hideCount()
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCellWithIdentifier(kLabelTableCellId, forIndexPath: indexPath) as! MenuLabelViewCell
            if  fetchedLabels?.fetchedObjects?.count ?? 0 > indexPath.row {
                if let data = fetchedLabels?.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as? Label {
                    cell.configCell(data)
                    cell.configUnreadCount()
                }
            }
            return cell
        } else {
            let cell: MenuTableViewCell = tableView.dequeueReusableCellWithIdentifier(kMenuTableCellId, forIndexPath: indexPath) as! MenuTableViewCell
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
}


extension MenuViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if !signingOut {
            tableView.endUpdates()
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if !signingOut {
            tableView.beginUpdates()
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        if !signingOut {
            switch(type) {
            case .Delete:
                tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Insert:
                tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if !signingOut {
            switch(type) {
            case .Delete:
                if let indexPath = indexPath {
                    tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 2)], withRowAnimation: UITableViewRowAnimation.Fade)
                }
            case .Insert:
                if let newIndexPath = newIndexPath {
                    tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: newIndexPath.row, inSection: 2)], withRowAnimation: UITableViewRowAnimation.Fade)
                }
            case .Move:
                if let indexPath = indexPath {
                    if let newIndexPath = newIndexPath {
                        tableView.moveRowAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 2), toIndexPath: NSIndexPath(forRow: newIndexPath.row, inSection: 2))
                    }
                }
            case .Update:
                if let indexPath = indexPath {
                    let index = NSIndexPath(forRow: indexPath.row, inSection: 2)
                    PMLog.D(index)
                    if let cell = tableView.cellForRowAtIndexPath(index) as? MenuLabelViewCell {
                        if  fetchedLabels?.fetchedObjects?.count ?? 0 > indexPath.row {
                            if let label = fetchedLabels?.objectAtIndexPath(indexPath) as? Label {
                                cell.configCell(label);
                                cell.configUnreadCount()
                            }
                        }
                    }
                }
            }
        }
    }
}
