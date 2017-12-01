//
//  Comment.swift
//  MedicConnect
//
//  Created by alessandro on 12/27/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import Foundation

public enum NotificationType : Int {
    case none = 0
    case like
    case comment
    case broadcast
    case newFollower
    case followRequest
    case requestAccepted
    case requestDeclined
    case blocked
}

class Notification {
    
    var id: String
    var notificationType : NotificationType
    var broadcast: Post?
    var date: String
    var message: String
    var fromUser: User

    init(id: String, notificationType: NotificationType, message: String, date: String, fromUser: User) {
        
        self.id = id
        self.notificationType = notificationType
        self.date = date
        self.fromUser = fromUser
        self.message = message
        
    }
    
    func getFormattedDate() -> String {
        
        let dDate = DateUtil.ParseStringDateToDouble(self.date) as NSDate
        let formattedDate = dDate.dateTimeAgo() as String? ?? ""
        
        return formattedDate
        
    }
}
