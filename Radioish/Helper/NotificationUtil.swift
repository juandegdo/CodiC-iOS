//
//  NotificationUtil.swift
//  Radioish
//
//  Created by a on 6/23/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Foundation
import UserNotifications
import UserNotificationsUI

let NewNotificationAlertDidChangeNotification = "NewNotificationAlertDidChangeNotification"

class NotificationUtil {
    static var hasNewNotification = false
    
    static func makeUserNotificationEnabled() {
        // iOS 10 support
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 9 support
        else if #available(iOS 9, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 8 support
        else if #available(iOS 8, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 7 support
        else {  
            UIApplication.shared.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
        }
    }
    static func isEnabledPushNotification()->Bool {
        let application = UIApplication.shared
        
        if application.isRegisteredForRemoteNotifications {
            if let unsettings = application.currentUserNotificationSettings {
                if unsettings.types.contains(UIUserNotificationType.alert) {
                    return true
                }
            }
        }
        
        return false
    }
    static func processPushNotificationSettings() {
        let alertController = UIAlertController(title: "Setting", message: "You must enable push notifications to use this feature.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        let goAction = UIAlertAction(title: "Go", style: .cancel) { (action) in
            self.goToAppSettings()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(goAction)
        
        if let w = UIApplication.shared.delegate?.window, let vc = w?.rootViewController {
            vc.present(alertController, animated: false, completion: nil)
        }
        
    }
    
    static func goToAppSettings(){
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    
    static func updateNotificationAlert(hasNewAlert: Bool) {
        hasNewNotification = hasNewAlert
        
        // Update notification flag on screens
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NewNotificationAlertDidChangeNotification), object: nil)
    }
    
}
