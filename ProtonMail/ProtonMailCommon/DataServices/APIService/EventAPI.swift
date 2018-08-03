//
//  EventAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/26/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

    
// MARK : Get messages part
final class EventCheckRequest<T : ApiResponse> : ApiRequest<T>{
    let eventID : String
    
    init(eventID : String) {
        self.eventID = eventID
    }
    
    override func path() -> String {
        return EventAPI.path + "/\(self.eventID)" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return EventAPI.v_get_events
    }
}


final class EventLatestIDRequest<T : ApiResponse> : ApiRequest<T>{

    override func path() -> String {
        return EventAPI.path + "/latest" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return EventAPI.v_get_latest_event_id
    }
}

final class EventLatestIDResponse : ApiResponse {
    var eventID : String = ""

    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        
        PMLog.D(response.json(prettyPrinted: true))
        self.eventID = response["EventID"] as? String ?? ""

        return true
    }
}

struct RefreshStatus : OptionSet {
    let rawValue: Int
    //255 means throw out client cache and reload everything from server, 1 is mail, 2 is contacts
    static let ok       = RefreshStatus(rawValue: 0)
    static let mail     = RefreshStatus(rawValue: 1 << 0)
    static let contacts = RefreshStatus(rawValue: 1 << 1)
    static let all      = RefreshStatus(rawValue: 0xFF)
}

final class EventCheckResponse : ApiResponse {
    var eventID : String = ""
    var refresh : RefreshStatus = .ok
    var more : Int = 0
    
    var messages : [[String : Any]]?
    var contacts : [[String : Any]]?
    var contactEmails : [[String : Any]]?
    var labels : [[String : Any]]?
    
    var subscription : [String : Any]? // for later
    
    var user : [String : Any]?
    var userSettings : [String : Any]?
    var mailSettings : [String : Any]?
    
    var vpnSettings : [String : Any]? // for later
    var invoices : [String : Any]? // for later
    var members : [[String : Any]]? // for later
    var domains : [[String : Any]]? // for later
    
    var addresses : [[String : Any]]?
    
    var organization : [String : Any]? // for later
    
    var messageCounts: [[String : Any]]?
    
    var conversationCounts: [[String : Any]]? // for later
    
    var usedSpace : String?
    var notices : [String]?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        //PMLog.D(response.JSONStringify(prettyPrinted: true))
        self.eventID = response["EventID"] as? String ?? ""
        self.refresh = RefreshStatus(rawValue: response["Refresh"] as? Int ?? 0)
        self.more    = response["More"] as? Int ?? 0
        
        self.messages      = response["Messages"] as? [[String : Any]]
        self.contacts      = response["Contacts"] as? [[String : Any]]
        self.contactEmails = response["ContactEmails"] as? [[String : Any]]
        self.labels        = response["Labels"] as? [[String : Any]]
        
        //self.subscription = response["Subscription"] as? [String : Any]
        
        self.user         = response["User"] as? [String : Any]
        self.userSettings = response["UserSettings"] as? [String : Any]
        self.mailSettings = response["MailSettings"] as? [String : Any]

        //self.vpnSettings = response["VPNSettings"] as? [String : Any]
        //self.invoices = response["Invoices"] as? [String : Any]
        //self.members  = response["Members"] as? [[String : Any]]
        //self.domains  = response["Domains"] as? [[String : Any]]
        
        self.addresses  = response["Addresses"] as? [[String : Any]]
        
        //self.organization = response["Organization"] as? [String : Any]
        
        self.messageCounts = response["MessageCounts"] as? [[String : Any]]
        
        //self.conversationCounts = response["ConversationCounts"] as? [[String : Any]]
        
        self.usedSpace = response["UsedSpace"] as? String
        self.notices = response["Notices"] as? [String]
        
        return true
    }
}

enum EventAction : Int {
    case delete = 0
    case insert = 1
    case update1 = 2
    case update2 = 3
    
    case unknown = 255
}

class Event {
    var action : EventAction
    var ID : String?
    
    init(id: String?, action: EventAction) {
        self.ID = id
        self.action = action
    }

}

final class MessageEvent {
    
    var Action : Int!
    var ID : String!;
    var message : [String : Any]?
    
    init(event: [String : Any]!) {
        self.Action = event["Action"] as! Int
        self.message =  event["Message"] as? [String : Any]
        self.ID =  event["ID"] as! String
        self.message?["ID"] = self.ID
        self.message?["needsUpdate"] = false
    }
}

final class ContactEvent {
    enum UpdateType : Int {
        case delete = 0
        case insert = 1
        case update = 2
        
        case unknown = 255
    }
    var action : UpdateType
    
    var ID : String!;
    var contact : [String : Any]?
    var contacts : [[String : Any]] = []
    init(event: [String : Any]!) {
        let actionInt = event["Action"] as? Int ?? 255
        self.action = UpdateType(rawValue: actionInt) ?? .unknown
        self.contact =  event["Contact"] as? [String : Any]
        self.ID =  event["ID"] as! String
        
        guard let contact = self.contact else {
            return
        }
        
        self.contacts.append(contact)
    }
}

final class EmailEvent {
    enum UpdateType : Int {
        case delete = 0
        case insert = 1
        case update = 2
        
        case unknown = 255
    }
    
    var action : UpdateType
    var ID : String!  //emailID
    var email : [String : Any]?
    var contacts : [[String : Any]] = []
    init(event: [String : Any]!) {
        let actionInt = event["Action"] as? Int ?? 255
        self.action = UpdateType(rawValue: actionInt) ?? .unknown
        self.email =  event["ContactEmail"] as? [String : Any]
        self.ID =  event["ID"] as? String ?? ""
        
        guard let email = self.email else {
            return
        }
        
        guard let contactID = email["ContactID"],
            let name = email["Name"] else {
            return
        }

        let newContact : [String : Any] = [
            "ID" : contactID,
            "Name" : name,
            "ContactEmails" : [email]
        ]
        self.contacts.append(newContact)
    }
    
}

final class LabelEvent {
    var Action : Int!
    var ID : String!;
    var label : [String : Any]?
    
    init(event: [String : Any]!) {
        self.Action = event["Action"] as! Int
        self.label =  event["Label"] as? [String : Any]
        self.ID =  event["ID"] as! String
    }
}


final class AddressEvent : Event {
    var address : [String : Any]?
    init(event: [String : Any]!) {
        let actionInt = event["Action"] as? Int ?? 255
        super.init(id: event["ID"] as? String,
                   action: EventAction(rawValue: actionInt) ?? .unknown)
        self.address =  event["Address"] as? [String : Any]
    }
}



