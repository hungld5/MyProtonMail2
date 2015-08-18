//
//  MailboxViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class MailboxViewModelImpl : MailboxViewModel {
    
    private let location : MessageLocation!
    
    init(location : MessageLocation) {
        
        self.location = location
        
        super.init()
    }
    
    override public func getNavigationTitle() -> String {
        return self.location.title
    }
    
    public override func getFetchedResultsController() -> NSFetchedResultsController? {
        let fetchedResultsController = sharedMessageDataService.fetchedResultsControllerForLocation(self.location)
        if let fetchedResultsController = fetchedResultsController {
            var error: NSError?
            if !fetchedResultsController.performFetch(&error) {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
        return fetchedResultsController
    }
    
    public override func lastUpdateTime() -> LastUpdatedStore.UpdateTime {
        return lastUpdatedStore.inboxLastForKey(self.location)
    }
    
    public override func getSwipeEditTitle() -> String {
        var title : String = "Trash"
        switch(self.location!) {
        case .trash, .spam:
            title = "Delete"
        default:
            title = "Trash"
        }
        return title
    }
    
    public override func deleteMessage(msg: Message) {
        switch(self.location!) {
        case .trash, .spam:
            msg.location = .deleted
        default:
            msg.location = .trash
        }
        msg.needsUpdate = true
        
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
    }
    
    public override func isDrafts() -> Bool {
        return self.location == MessageLocation.draft
    }
    
    public override func isCurrentLocation(l: MessageLocation) -> Bool {
        return self.location == l
    }
    
    override func fetchMessages(MessageID: String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        sharedMessageDataService.fetchMessagesForLocation(self.location, MessageID: MessageID, Time:Time, foucsClean: foucsClean, completion:completion)
    }
    
    override func fetchNewMessages(Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchNewMessagesForLocation(self.location, Time: Time, completion: completion)
    }

    override func fetchMessagesForLocationWithEventReset(MessageID: String, Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchMessagesForLocationWithEventReset(self.location, MessageID: MessageID, Time: Time, completion: completion)
    }
    
}