//
//  History.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2018-04-13.
//  Copyright © 2018 Loewen. All rights reserved.
//

import Foundation

class History {
    
    var id: String
    var meta: Meta
    var callId: String
    var callState: Int
    var duration: Double
    var fromUser: User
    var toUser: User
    var type: String
    
    init (id: String, meta: Meta, callId: String, callState: Int, duration: Double, fromUser: User, toUser: User, type: String) {
        
        self.id = id
        self.meta = meta
        self.callId = callId
        self.callState = callState
        self.duration = duration
        self.fromUser = fromUser
        self.toUser = toUser
        self.type = type
        
    }
    
    func getFormattedDate() -> String {
        
        let dDate = DateUtil.ParseStringDateToDouble(self.meta.createdAt) as Date
        let formattedDate = DateUtil.GetBirthDate(dDate) as String? ?? ""
        
        return formattedDate
        
    }
    
}
