//
//  UserManager.swift
//  ProtonMail - Created on 8/15/19.
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


import Foundation

/// TODO:: this is temp
protocol UserDataSource : class {
    var mailboxPassword : String { get }
    var newSchema : Bool {get}
    var addressKeys : [Key] { get }
    var userPrivateKeys : Data { get }
    var userInfo : UserInfo { get }
    var addressPrivateKeys : Data { get }
    var authCredential : AuthCredential { get }
    func getAddressKey(address_id : String) -> Key?
    func getAddressPrivKey(address_id : String) -> String
}

///
class UserManager : Service {
    
    //weak var delegate : UsersManagerDelegate?
    
    public let apiService : APIService
    public var userinfo : UserInfo
    public var auth : AuthCredential

    //public let user
    
    public lazy var reportService: BugDataService = {
        let service = BugDataService(api: self.apiService)
        return service
    }()
    public lazy var contactService: ContactDataService = {
        let service = ContactDataService(api: self.apiService, userID: self.userinfo.userId)
        return service
    }()
    
    public lazy var messageService: MessageDataService = {
        // can try to reuse the contactService
        let service = MessageDataService(api: self.apiService, userID: self.userinfo.userId)
        service.userDataSource = self
        return service
    }()
    
    public lazy var labelService: LabelsDataService = {
        let service = LabelsDataService(api: self.apiService, userID: self.userinfo.userId)
        return service
    }()
    
    public lazy var userService: UserDataService = {
        let service = UserDataService(check: false, api: self.apiService)
        return service
    }()

    init(api: APIService, userinfo: UserInfo, auth: AuthCredential) {
        self.userinfo = userinfo
        self.auth = auth
        self.apiService = api
        self.apiService.sessionDeleaget = self
    }
    
    public func isMatch(sessionID uid : String) -> Bool {
        return auth.sessionID == uid
    }
}

extension UserManager : SessionDelegate {
    func getToken(bySessionUID uid: String) -> String? {
        //TODO:: check session UID later
        return auth.token
    }
}


extension UserManager : UserDataSource {
    func getAddressPrivKey(address_id: String) -> String {
         return ""
    }
    
    func getAddressKey(address_id: String) -> Key? {
        return self.userInfo.getAddressKey(address_id: address_id)
    }
    
    var userPrivateKeys: Data {
        get {
            self.userinfo.userPrivateKeys
        }
    }
    
    var addressKeys: [Key] {
        get {
            return self.userinfo.addressKeys
        }
    }
    
    var newSchema: Bool {
        get {
            return self.userinfo.newSchema
        }
    }
    
    var mailboxPassword: String {
        get {
            return self.auth.password
        }
    }
    
    
    var userInfo : UserInfo {
        get {
            return self.userinfo
        }
        
    }
    
    var addressPrivateKeys : Data {
        get {
            return self.userinfo.addressPrivateKeys
        }        
    }
    
    var authCredential : AuthCredential {
        get {
            return self.auth
        }
    }
}


/// Get values
extension UserManager {
    var defaultDisplayName : String {
        if let addr = userinfo.userAddresses.defaultAddress() {
            return addr.display_name
        }
        return displayName
    }
    
    var defaultEmail : String {
        if let addr = userinfo.userAddresses.defaultAddress() {
            return addr.email
        }
        return ""
    }
    
    var displayName: String {
        return userinfo.displayName.decodeHtml()
    }
    
    var addresses : [Address] {
        return userinfo.userAddresses
    }
    
    var autoLoadRemoteImages: Bool {
        return userInfo.autoShowRemote
    }
    
    var userDefaultSignature: String {
        return userInfo.defaultSignature.ln2br()
    }
    
    var showMobileSignature : Bool {
        get {
            #if Enterprise
            let isEnterprise = true
            #else
            let isEnterprise = false
            #endif
            //TODO:: fix me
            let role = userInfo.role
            if role > 0 || isEnterprise {
                return sharedUserDataService.switchCacheOff == false
            } else {
                sharedUserDataService.switchCacheOff = false
                return true
            } }
        set {
            sharedUserDataService.switchCacheOff = (newValue == false)
        }
    }
    
    var mobileSignature : String {
        get {
            #if Enterprise
            let isEnterprise = true
            #else
            let isEnterprise = false
            #endif
            let role = userInfo.role
            if role > 0 || isEnterprise {
                return userCachedStatus.mobileSignature
            } else {
                userCachedStatus.resetMobileSignature()
                return userCachedStatus.mobileSignature
            }
        }
        set {
            userCachedStatus.mobileSignature = newValue
        }
    }
    
    
    
}
