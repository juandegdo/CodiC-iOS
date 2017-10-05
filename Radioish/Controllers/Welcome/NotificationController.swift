//
//  PostController.swift
//  Radioish
//
//  Created by Akio Yamadera on 19/06/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Foundation

class NotificationController {
    
    static let Instance = NotificationController()
    
    fileprivate var notifications: [Notification] = []
    
    //MARK: Recommended posts
    
    func getNotifications() -> [Notification] {
        return self.notifications //.reversed()
    }
    
    func setNotifications(_ notifications: [Notification]) {
        self.notifications = notifications
    }
    
}
