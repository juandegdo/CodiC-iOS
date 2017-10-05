//
//  PlaylistService.swift
//  Radioish
//
//  Created by Daniel Yang on 2017-08-15.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Alamofire
import Foundation

class PlaylistService: BaseTaskController {
    static let Instance = PlaylistService()
    
    func addToPlaylist(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPlaylist)\(self.URLAddToPlaylistSuffix)"
        let parameters = ["playlistUserId" : userId]
        
        manager!.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default)
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
    
    func removeUserFromPlaylist(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPlaylist)\(self.URLRemovePlaylistUserSuffix)"
        let parameters = ["playlistUserId" : userId]
        
        manager!.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default)
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
    
    func getPlaylist(_ skip : Int = 0, limit: Int = 1000, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPlaylist)\(self.URLGetPlaylistSuffix)?skip=\(skip)&limit=\(limit)"
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                var playlistPosts: [Post] = []
                
                if response.response?.statusCode == 200 {
                    
                    if let _posts = response.result.value as? [[String : AnyObject]] {
                        
                        for _p in _posts {
                            
                            if  let _id = _p["_id"] as? String,
                                let _audio = _p["audio"] as? String,
                                let metaDic = _p["meta"] as? [String : String],
                                let _createdAt = metaDic["created_at"] as String?,
                                let _playCount = _p["play_count"] as? Int,
                                let _commentsCount = _p["comments_count"] as? Int,
                                let _title = _p["title"] as? String,
                                let _userObj = _p["user"] as? NSDictionary,
                                let _userId = _userObj["_id"] as? String,
                                let _name = _userObj["name"] as? String {
                                
                                // Create Meta
                                let _meta = Meta(createdAt: _createdAt)
                                
                                if let _updatedAt = metaDic["updated_at"] as String? {
                                    _meta.updatedAt = _updatedAt
                                }
                                
                                // Create User
                                let _user = User(id: _userId, fullName: _name, email: "")
                                
                                if let _userPhoto = _userObj["photo"] as? String {
                                    _user.photo = _userPhoto
                                }
                                
                                if let _userFollowing = _userObj["following"] as? [AnyObject] {
                                    _user.following = _userFollowing
                                }
                                
                                if let _userFollowers = _userObj["followers"] as? [AnyObject] {
                                    _user.follower = _userFollowers
                                }
                                
                                if let _userDescription = _userObj["description"] as? String {
                                    _user.description = _userDescription
                                }
                                
                                
                                // Create final Post
                                let post = Post(id: _id, audio: _audio, meta: _meta, playCount: _playCount, commentsCount: _commentsCount, title: _title, user: _user)
                                
                                // Optional description
                                
                                if let _description = _p["description"] as? String {
                                    post.description = _description
                                }
                                
                                // Optional likes
                                
                                if let _likes = _p["likes"] as? [String] {
                                    
                                    post.likes = _likes
                                }
                                
                                // Optional like description
                                
                                if let _likeDescription = _p["like_description"] as? String {
                                    post.likeDescription = _likeDescription
                                }
                                
                                // Optional commentedUsers
                                
                                if let _commentedUsers = _p["commented_users"] as? [String] {
                                    
                                    post.commentedUsers = _commentedUsers
                                }
                                
                                playlistPosts.append(post)
                                
                            }
                            
                        }
                        
                        PlaylistController.Instance.setPlaylistPosts(playlistPosts)
                        completion(true)
                        
                    } else {
                        
                        PlaylistController.Instance.setPlaylistPosts([])
                        completion(false)
                        
                    }
                    
                    
                } else {
                    
                    PlaylistController.Instance.setPlaylistPosts([])
                    completion(false)
                    
                }
                
        }
        
    }
    
}
