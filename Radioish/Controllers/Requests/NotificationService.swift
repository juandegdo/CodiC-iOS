//
//  PostService.swift
//  Radioish
//
//  Created by Akio Yamadera on 17/06/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Alamofire
import Foundation

class NotificationService: BaseTaskController {
    
    static let Instance = NotificationService()
    
    func markAsRead(_ unreadId: String, completion: @escaping (_ success: Bool, _ count: Int?) -> Void) {
        let url = "\(self.baseURL)\(self.URLNotification)/markread/\(unreadId)"
        manager!.request(url, method: .post, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false, nil)
                    return
                }
                
                if let value = response.result.value as? Dictionary<String, Any> {
                    completion(response.response?.statusCode == 200, value["count"] as? Int)
                } else {
                    completion(response.response?.statusCode == 200, nil)
                }
        }
    }
    
    func markAllAsRead(completion: @escaping (_ success: Bool) -> Void) {
        let url = "\(self.baseURL)\(self.URLNotification)/allread/markallread"
        manager!.request(url, method: .post, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                completion(response.response?.statusCode == 200)
        }
    }
    
    func getNotifications(_ skip : Int = 0, limit: Int = 1000, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLNotification)?skip=\(skip)&limit=\(limit)"
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                var notifications: [Notification] = []
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let _notifications = response.result.value as? [[String : AnyObject]] {
                        var firstNotifcation = true
                        
                        for n in _notifications {
                            
                            if  let _nid = n["_id"] as? String,
                                let _message = n["message"] as? String,
                                let _notificationType = n["notificationType"] as? Int,
                                let metaDic = n["meta"] as? [String : String],
                                let _createdAt = metaDic["created_at"] as String?,
                                let _userObj = n["fromUser"] as? NSDictionary {
                                
                                if firstNotifcation {
                                    firstNotifcation = false
                                    
                                    if _nid != UserDefaultsUtil.LoadLastNotificationID() {
                                        UserDefaultsUtil.SaveLastNotificationID(id: _nid)
                                    }
                                }
                                
                                let _id = _userObj["_id"] as! String
                                let _name = _userObj["name"] as! String
                                
                                let _user = User(id: _id, fullName: _name)
                                
                                if let _userPhoto = _userObj["photo"] as? String {
                                    _user.photo = _userPhoto
                                }
                                
                                if let _userFollowing = _userObj["following"] as? [AnyObject] {
                                    _user.following = _userFollowing
                                }
                                
                                if let _userFollowers = _userObj["followers"] as? [AnyObject] {
                                    _user.follower = _userFollowers
                                }
                                
                                if let _blocking = _userObj["blocking"] as? [AnyObject] {
                                    _user.blocking = _blocking
                                }
                                
                                if let _blockedBy = _userObj["blockedby"] as? [AnyObject] {
                                    _user.blockedby = _blockedBy
                                }
                                
                                if let _requested = _userObj["requested"] as? [AnyObject] {
                                    _user.requested = _requested
                                }
                                
                                if let _requesting = _userObj["requesting"] as? [AnyObject] {
                                    _user.requesting = _requesting
                                }
                                
                                if let _userDescription = _userObj["description"] as? String {
                                    _user.description = _userDescription
                                }
                                
                                let notification = Notification(id: _nid, notificationType: NotificationType(rawValue: _notificationType)!, message: _message, date: _createdAt, fromUser: _user)
                                
                                if let _broadcastObj = n["broadcast"] as? NSDictionary,
                                    let _id = _broadcastObj["_id"] as? String,
                                    let _audio = _broadcastObj["audio"] as? String,
                                    let _metaDic = _broadcastObj["meta"] as? [String : String],
                                    let _createdAt = _metaDic["created_at"] as String?,
                                    let _playCount = _broadcastObj["play_count"] as? Int,
                                    let _commentsCount = _broadcastObj["comments_count"] as? Int,
                                    let _title = _broadcastObj["title"] as? String {
                                    
                                    // Create Meta
                                    let _meta = Meta(createdAt: _createdAt)
                                    
                                    if let _updatedAt = metaDic["updated_at"] as String? {
                                        _meta.updatedAt = _updatedAt
                                    }
                                    
                                    // Create final Post
                                    let post = Post(id: _id, audio: _audio, meta: _meta, playCount: _playCount, commentsCount: _commentsCount, title: _title, user: _user)
                                    
                                    // Optional description
                                    
                                    if let _description = _broadcastObj["description"] as? String {
                                        post.description = _description
                                    }
                                    
                                    // Optional likes
                                    
                                    if let _likes = _broadcastObj["likes"] as? [String] {
                                        
                                        post.likes = _likes
                                    }
                                    
                                    // Optional commentedUsers
                                    
                                    if let _commentedUsers = _broadcastObj["commented_users"] as? [String] {
                                        
                                        post.commentedUsers = _commentedUsers
                                    }
                                    
                                    notification.broadcast = post
                                    
                                }
                                
                                notifications.append(notification)
                                
                            }
                            
                        }
                        
                        NotificationController.Instance.setNotifications(notifications)
                        completion(true)
                        
                    } else {
                        
                        NotificationController.Instance.setNotifications([])
                        completion(false)
                        
                    }
                    
                    
                } else {
                    
                    NotificationController.Instance.setNotifications([])
                    completion(false)
                    
                }
                
        }
        
    }
    
}
