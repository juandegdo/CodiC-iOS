//
//  PostService.swift
//  MedicConnect
//
//  Created by Akio Yamadera on 17/06/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Alamofire
import Foundation

class CommentService: BaseTaskController {
    
    static let Instance = CommentService()
    
    func postComment(_ postId: String, content: String, completion: @escaping (_ success: Bool, _ comment: Comment?) -> Void) {
        
        guard let url = URL(string: "\(self.baseURL)\(self.URLComment)/\(postId)") else {
            return
        }
        
        let parameters = ["content" : content]
        
        manager!.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false, nil)
                    return
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let status = response.result.value as? [String : AnyObject] {
                        
                        if  let c = status["comment"] as? [String: AnyObject],
                            let _content = c["content"] as? String,
                            let metaDic = c["meta"] as? [String : String],
                            let _createdAt = metaDic["created_at"] as String? {
                            
                            // Create final Post
                            let _comment = Comment(date: _createdAt, comment: _content)
                            completion(true, _comment)
                            
                        } else {
                            completion(false, nil)
                        }
                        
                    } else {
                        
                        completion(false, nil)
                        
                    }
                    
                    
                } else {
                    
                    completion(false, nil)
                    
                }
                
        }
    }
    
    func getComments(_ postId: String, skip : Int = 0, limit: Int = 100, completion: @escaping (_ success: Bool) -> Void) {
    
        let url = "\(self.baseURL)\(self.URLComment)/\(postId)?skip=\(skip)&limit=\(limit)"
    
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                var comments: [Comment] = []
                
                if response.response?.statusCode == 200 {
                    
                    if let _comments = response.result.value as? [[String : AnyObject]] {
                        
                        for c in _comments {
                            
                            if  let _content = c["content"] as? String,
                                let metaDic = c["meta"] as? [String : String],
                                let _createdAt = metaDic["created_at"] as String?,
                                let _userObj = c["user"] as? NSDictionary,
                                let _userId = _userObj["_id"] as? String,
                                let _name = _userObj["name"] as? String {
                                
                                // Create User
                                let _user = User(id: _userId, fullName: _name, email: "")
                                
                                var _photo = ""
                                if let _userPhoto = _userObj["photo"] as? String {
                                    _photo = _userPhoto
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
                                
                                if let _blockedBy = _userObj["blockedby"] as? [String] {
                                    _user.blockedby = _blockedBy as [AnyObject]
                                    if let _user = UserController.Instance.getUser() as User?, _blockedBy.contains(_user.id) {
                                        continue
                                    }
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
                                
                                // Create final Post
                                let comment = Comment(url: _photo, author: _name, date: _createdAt, comment: _content, user: _user)
                                
                                comments.append(comment)
                                
                            }
                            
                        }
                        
                        CommentController.Instance.setComments(comments)
                        completion(true)
                        
                    } else {
                        
                        CommentController.Instance.setComments([])
                        completion(false)
                        
                    }
                    
                    
                } else {
                    
                    CommentController.Instance.setComments([])
                    completion(false)
                    
                }
                
        }
        
    }
    
}
