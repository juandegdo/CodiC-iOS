//
//  Post.swift
//  MedicConnect
//
//  Created by Alessandro Zoffoli on 23/03/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Foundation
import AVFoundation
import NSDate_TimeAgo

class Post {
    
    var id: String
    var audio: String
    var meta: Meta
    var playCount: Int
    var title: String
    var description: String
    var user: User
    var likes: [String] = []
    var likeDescription: String = ""
    var commentsCount: Int
    var commentedUsers: [String] = []
    var hashtags: [String] = []
    var postType: String
    
    fileprivate var currentTime: CMTime = CMTime(seconds: 0.0, preferredTimescale: CMTimeScale(1.0))
    fileprivate var currentProgress: CGFloat = 0.0
    fileprivate var lastPlayedAt: Double = DateUtil.getDistantPast()
    
    init(id: String, audio: String, meta: Meta, playCount: Int, commentsCount: Int, title: String, description: String, user: User, postType: String) {
        
        self.id = id
        self.audio = audio
        self.meta = meta
        self.playCount = playCount
        self.commentsCount = commentsCount
        self.title = title
        self.description = description
        self.user = user
        self.postType = postType
        
    }
    
    init(id: String, audio: String, meta: Meta, playCount: Int, commentsCount: Int, title: String, author: String, postType: String) {
        
        self.id = id
        self.audio = audio
        self.meta = meta
        self.playCount = playCount
        self.commentsCount = commentsCount
        self.title = title
        self.description = ""
        self.user = User(fullName: author, email: "", password: "")
        self.postType = postType
        
    }
    
    init(id: String, audio: String, meta: Meta, playCount: Int, commentsCount: Int, title: String, description: String, postType: String) {
        
        self.id = id
        self.audio = audio
        self.meta = meta
        self.playCount = playCount
        self.commentsCount = commentsCount
        self.title = title
        self.description = description
        self.user = User(email: "", password: "")
        self.postType = postType
        
    }
    
    init(id: String, audio: String, meta: Meta, playCount: Int, commentsCount: Int, title: String, user: User, postType: String) {
        
        self.id = id
        self.audio = audio
        self.meta = meta
        self.playCount = playCount
        self.commentsCount = commentsCount
        self.title = title
        self.description = ""
        self.user = user
        self.postType = postType
        
    }
    
    func getFormattedDate() -> String {
        
        let dDate = DateUtil.ParseStringDateToDouble(self.meta.createdAt) as NSDate
        let formattedDate = dDate.dateTimeAgo() as String? ?? ""
        
        return formattedDate
        
    }
    
    func getCurrentProgress() -> CGFloat {
                
        if self.getLastPlayedMinutesAgo() == 0 {
            return 0.0
        } else {
            return self.currentProgress
        }
        
    }
    
    func getCurrentTime() -> CMTime {
        
//        if self.getLastPlayedMinutesAgo() == 0 {
//            return CMTime(seconds: 0.0, preferredTimescale: CMTimeScale(1.0))
//        } else {
//            return self.currentTime
//        }
        return self.currentTime
        
    }
    
    func setPlayed(time: CMTime, progress: CGFloat, setLastPlayed: Bool = true) {
        
        self.currentTime = time
        self.currentProgress = progress
        
        if setLastPlayed {
            self.lastPlayedAt = DateUtil.getNow()
        }

    }
    
    func getLastPlayedMinutesAgo() -> Int {
        
        return DateUtil.getMinutesAgo(NSNumber(value: self.lastPlayedAt))
    }
    
    func resetCurrentTime() {
        
        self.currentTime = CMTime(seconds: 0, preferredTimescale: CMTimeScale(1.0))
        
    }
    
    func hasLiked(id: String) -> Bool {
        
        return self.likes.contains(id)
        
    }
    
    func addLike(id: String) {
        print("addLike")
        self.likes.append(id)
    }
    
    func removeLike(id: String) {
        print("removeLike")
        for index in 0..<self.likes.count {
            if id == self.likes[index] {
                self.likes.remove(at: index)
                return
            }
        }
        
    }
    
    func hasCommented(id: String) -> Bool {
        
        return self.commentedUsers.contains(id)
        
    }
    
    func addCommentedUser(id: String) {
        print("addCommentedUser")
        self.commentedUsers.append(id)
    }
    
    func removeCommentedUser(id: String) {
        print("removeCommentedUser")
        for index in 0..<self.commentedUsers.count {
            if id == self.commentedUsers[index] {
                self.commentedUsers.remove(at: index)
                return
            }
        }
        
    }
    
}
