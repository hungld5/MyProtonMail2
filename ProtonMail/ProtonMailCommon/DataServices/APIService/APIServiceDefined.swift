//
//  APIServiceRequest.swift
//  ProtonMail
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

//*******************************************************************************************
//ProtonMail API Doc : https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api.md
//ProtonMail API Doc : http://185.70.40.19:3001/#messages-send-message-post
//*******************************************************************************************


//Addresses API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_addresses.md
struct AddressesAPI {
    /// base message api path
    static let path :String = Constants.App.API_PATH + "/addresses"
    
    //Create new address [POST /addresses] locked
    
    //Order Addresses [/addresses/order]
    static let v_update_order : Int = 3
    
    //Setup new non-subuser address [POST /addresses/setup]
    static let v_setup : Int = 3
    
    //Get Addresses [GET /addresses]
    static let v_get_addresses : Int = 3
    //Get Address [GET /addresses/{address_id}]
    
    //Update address [PUT]
    static let v_update_address : Int = 3
    
}

//Not impl yet, maybe use in the future
struct AdminAPI {
    //Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_admin.md
}

//Not impl yet, maybe use in the future
struct AdminVPNAPI {
    //Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_admin_vpn.md
}

//Attachment API
//Doc:https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_attachments.md
struct AttachmentAPI {
    /// base message api path
    static let path :String = Constants.App.API_PATH + "/attachments"

    
    /// get attachment by id
    static let v_get_att_by_id : Int = 3
    
    /// upload attachment
    static let v_upload_attach : Int = 3
    
    /// update draft attachment signature
    static let v_update_att_sign : Int = 3
    
    /// delete attachment from draft
    static let v_del_attachment : Int = 3
}

//Auth API
//Doc:https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_auth.md
struct AuthAPI {
    /// base message api path
    static let path :String = Constants.App.API_PATH + "/auth"
    
    /// user auth post
    static let v_auth : Int = 3
    
    /// refresh token post
    static let v_auth_refresh : Int = 3
    
    /// setup auth info post
    static let v_auth_info : Int = 3
    
    /// get random srp modulus
    static let v_get_auth_modulus : Int = 3
    
    /// delete auth
    static let v_delete_auth : Int = 3
    
    /// revoke other tokens
    static let v_revoke_others : Int = 3

    /// submit 2fa code
    static let v_auth_2fa : Int = 3
}

//Contact API
//Doc:https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_contacts_v2.md
struct ContactsAPI {
    
    static let path : String = Constants.App.API_PATH + "/contacts"
    
    /// get contact list. no details. only name, email, labels for displaying
    static let v_get_contacts : Int = 3
    /// get contact email list. this is for auto complete. combine with contacts would be full information without encrypted data.
    static let v_get_contact_emails : Int = 3
    /// add & import contact post
    static let v_add_contacts : Int = 3
    /// get contact details full date clear&encrypt data
    static let v_get_details : Int = 3
    /// update contact put
    static let v_update_contact : Int = 3
    /// delete contact put
    static let v_delete_contacts : Int = 3
    
    /// group
    /// label an array of emails to a certain contact group
    static let v_label_an_array_of_contact_emails: Int = 3
    
    /// unlabel an array of emails from a certain contact group
    static let v_unlabel_an_array_of_contact_emails: Int = 3
    
    /// export
    
    /// clear contacts
}

//Device API
//Doc:https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_devices.md
struct DeviceAPI {
    
    static let path : String = Constants.App.API_PATH + "/devices"
    
    /// register a device POST
    static let v_register_device : Int = 3
    
    /// delete a registered device post
    static let v_delete_device : Int = 3
}

//Domains API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_domains.md
struct DomainsAPI {
    
    static let path : String = Constants.App.API_PATH + "/domains"
    
    //Get all domains for this user's organization and check their DNS's [GET]
    
    //Get a specific domains and its check DNS [GET]
    
    //Get Available Domains [GET /domains/available]
    static let v_available_domains : Int = 3
    
    //Get Premium Domains [GET /domains/premium]
    
    //Create Domain [POST /domains]
    
    //Delete Domain [DELETE /domains/{domainid}]
}

//Events API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_events_v3.md
struct EventAPI {
    /// base event api path
    static let path :String = Constants.App.API_PATH + "/events"
    
    /// get latest event id
    static let v_get_latest_event_id : Int = 3
    
    /// get updated events based on latest event id
    static let v_get_events : Int = 3
    
}

//Keys API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_keys.md
struct KeysAPI {
    static let path : String = Constants.App.API_PATH + "/keys"
    
    /// Update private keys only, use for mailbox password/single password updates PUT
    static let v_update_private_key : Int = 3
    
    /// Setup keys for new account, private user [POST]
    static let v_setup_key : Int = 3
    
    /// Get key salts, locked route [GET]
    static let v_get_key_salts : Int = 3
    
    /// Get public keys [GET]
    static let v_get_emails_pub_key : Int = 3
}

//Labels API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_labels.md
struct LabelAPI {
    static let path :String = Constants.App.API_PATH + "/labels"
    
    /// Get user's labels [GET]
    static let v_get_user_labels : Int = 3
    
    /// Create new label [POST]
    static let v_create_label : Int = 3
    
    /// Update existing label [PUT]
    static let v_update_label : Int = 3
    
    /// Delete a label [DELETE]
    static let v_delete_label : Int = 3
    
    //doesn't impl yet
    /// Change label priority [PUT]
    static let v_order_labels : Int = 3
}

//Message API
//Doc: V1 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_messages.md
//Doc: V3 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_messages_v3.md
struct MessageAPI {
    /// base message api path
    static let path :String = Constants.App.API_PATH + "/messages"
    
    //Get a list of message metadata [GET]
    static let v_fetch_messages : Int = 3
    
    //Get grouped message count [GET]
    static let v_message_count : Int = 3
    
    static let v_create_draft : Int = 3
    
    static let v_update_draft : Int = 3
    
    // inlcude read/unread
    static let V_MessageActionRequest : Int = 3
    
    //Send a message [POST]
    static let v_send_message : Int = 3
    
    //Label/move an array of messages [PUT]
    static let v_label_move_msgs : Int = 3
    
    //Unlabel an array of messages [PUT]
    static let v_unlabel_msgs : Int = 3
    
    //Delete all messages with a label/folder [DELETE]
    static let v_empty_label_folder : Int = 3
    
    //Delete an array of messages [PUT]
    static let v_delete_msgs : Int = 3
    
    //Undelete Messages [/messages/undelete]
    static let v_undelete_msgs : Int = 3
    
    //Label/Move Messages [/messages/label] [PUT]
    static let v_apply_label_to_messages : Int = 3
    
    //Unlabel Messages [/messages/unlabel] [PUT]
    static let v_remove_label_from_message : Int = 3
}

//Organization API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_organizations.md
struct OrganizationsAPI {
    static let Path : String = Constants.App.API_PATH + "/organizations"
    
    /// Get organization keys [GET]
    static let v_get_org_keys : Int = 3
}


/**
 [ProtonMail Reports API]:
 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_reports.md "Report bugs"
 
 Reports API
 - Doc: [ProtonMail Reports API]
 */
struct ReportsAPI {
    static let path :String = Constants.App.API_PATH + "/reports"
    
    /// Report a bug [POST]
    static let v_reports_bug : Int = 3
    
    static let v_reports_phishing : Int = 3
}

/**
 [Settings API Part 1]:
 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_mail_settings.md
 [Settings API Part 2]:
 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_settings.md
 
 Settings API
 - Doc: [Settings API Part 1], [Settings API Part 2]
 */
struct SettingsAPI {
    /// base settings api path
    static let path :String = Constants.App.API_PATH + "/settings"
    
    /// Get general settings [GET]
    static let v_get_general_settings : Int = 3
    
    /// Turn on/off email notifications [PUT]
    static let v_update_notify : Int = 3
    
    /// Update email [PUT]
    static let v_update_email : Int = 3
    
    /// Update swipe left flag [PUT]
    static let v_update_swipe_left_right : Int = 3
    
    /// Update swipe right flag [PUT]
    static let v_update_swipe_right_left : Int = 3
    
    /// Update newsletter subscription [PUT]
    static let v_update_sub_news : Int = 3
    
    /// Update display name [PUT]
    static let v_update_display_name : Int = 3
    
    /// Update images bits [PUT]
    static let v_update_shwo_images : Int = 3
    
    /// Update login password [PUT]
    static let v_update_login_password : Int = 3
    
    /// Update login password [PUT]
    static let v_update_link_confirmation : Int = 3
}

//Users API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_users.md
struct UsersAPI {
    //
    static let path : String = Constants.App.API_PATH + "/users"
    
    /// Check if username already taken [GET]
    static let v_check_is_user_exist : Int = 3
    
    /// Check if direct user signups are enabled [GET]
    static let v_get_user_direct : Int = 3
    
    /// Get user's info [GET]
    static let v_get_userinfo : Int = 3
    
    /// Get options for human verification [GET]
    static let v_get_human_verify_options : Int = 3
    
    /// Verify user is human [POST]
    static let v_verify_human : Int = 3
    
    /// Create user [POST]
    static let v_create_user : Int = 3
    
    /// Send a verification code [POST]
    static let v_send_verification_code : Int = 3
}

//Payments API
//Doc: FIXME
struct PaymentsAPI {
    static let path : String = Constants.App.API_PATH + "/payments"
    
    static let v_get_status: Int = 3
    static let v_get_plans: Int = 3
    static let v_get_payment_methods: Int = 3
    static let v_get_subscription: Int = 3
    static let v_get_default_plan: Int = 3
    static let v_post_credit: Int = 3
    static let v_post_subscription: Int = 3
    
    static let v_get_apple_tier : Int = 3
}

