//
//  Broadcast.swift
//  Radioish
//
//  Created by alessandro on 1/3/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Foundation

class Broadcast {
    
    var bannerURL: String
    var broadcastName: String
    var playCount: Int
    var userName: String
    var isPlaying: Bool
    
    init(bannerURL: String, broadcastName: String, playCount: Int, userName: String, isPlaying: Bool) {
        
        self.bannerURL = bannerURL
        self.broadcastName = broadcastName
        self.playCount = playCount
        self.userName = userName
        self.isPlaying = isPlaying
        
    }

}
