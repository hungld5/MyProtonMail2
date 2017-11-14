//
//  NotificationViewController.swift
//  PushDev
//
//  Created by Yanfeng Zhang on 11/13/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

@available(iOSApplicationExtension 10.0, *)
class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        self.label?.text = notification.request.content.body
    }

}
