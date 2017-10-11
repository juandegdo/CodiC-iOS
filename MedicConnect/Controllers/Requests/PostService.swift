//
//  PostService.swift
//  MedicConnect
//
//  Created by Alessandro Zoffoli on 19/03/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Alamofire
import Foundation

class PostService: BaseTaskController {
    
    static let Instance = PostService()
    
    func sendPost(_ title: String, author: String, description: String, hashtags: [String], audioData: Data, image: UIImage?, fileExtension: String, mimeType: String, completion: @escaping (_ success: Bool) -> Void) {
        
        guard let _url = URL(string: "\(self.baseURL)\(self.URLPost)") else {
            return
        }
        
        
        let token = UserDefaultsUtil.LoadToken()
        let bearer = "Bearer \(token)"
        let headers = ["Authorization" : bearer, "user-agent" : UIDevice.current.identifierForVendor!.uuidString.sha1()]
        let urlRequest = try! URLRequest(url: _url, method: .post, headers: headers)
        let parameters = ["title" : title,
                          "author" : author,
                          "description" : description,
                          "hashtags" : hashtags.count > 0 ? hashtags.joined(separator: ",") : ""]
        
        Alamofire.upload(multipartFormData: { (multipartFormData ) in
            
            multipartFormData.append(audioData, withName: "audio", fileName: "\(Date().timeIntervalSinceReferenceDate).\(fileExtension)", mimeType: "\(mimeType)")
            
            if let _image = image as UIImage?,
                let _imageData = UIImagePNGRepresentation(_image) as Data? {
                
                multipartFormData.append(_imageData, withName: "image", fileName: "\(Date().timeIntervalSinceReferenceDate).png", mimeType: "image/png")
            }
            
            
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
        }, with: urlRequest) { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.responseJSON { response in
                    print("\n=======================\n")
                    debugPrint(response)
                    print("\n=======================\n")
                    completion(true)
                }
                
            case .failure(let encodingError):
                print("\n=======================\n")
                print(encodingError)
                print("\n=======================\n")
                completion(false)
            }
        }
    }
    
    func getPosts(completion: @escaping (_ success: Bool) -> Void) {
    
        let url = "\(self.baseURL)\(self.URLPost)/all"
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                var posts: [Post] = []
                
                if response.response?.statusCode == 200 {
                    
                    if let _posts = response.result.value as? [[String : AnyObject]] {
                        
                        for p in _posts {
                            
                            if let _id = p["_id"] as? String,
                                let _audio = p["audio"] as? String,
                                let _createdAt = p["createdAt"] as? String,
                                let _playCount = p["play_count"] as? Int,
                                let _commentsCount = p["comments_count"] as? Int,
                                let _title = p["title"] as? String,
                                let _description = p["description"] as? String,
                                let _userObj = p["user"] as? NSDictionary,
                                let _userId = _userObj["_id"] as? String,
                                let _name = _userObj["name"] as? String {
                                
                                // Create Meta
                                let _meta = Meta(createdAt: _createdAt)
                                
                                if let _updatedAt = p["updatedAt"] as? String {
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
                                let post = Post(id: _id, audio: _audio, meta: _meta, playCount: _playCount, commentsCount: _commentsCount, title: _title, description: _description, user: _user)
                                
                                // Optional description
                                
                                if let _description = p["description"] as? String {
                                    post.description = _description
                                }
                                
                                // Optional likes
                                
                                if let _likes = p["likes"] as? [String] {
                                    
                                    post.likes = _likes
                                }
                                
                                // Optional like description
                                
                                if let _likeDescription = p["like_description"] as? String {
                                    post.likeDescription = _likeDescription
                                }
                                
                                // Optional commentedUsers
                                
                                if let _commentedUsers = p["commented_users"] as? [String] {
                                    
                                    post.commentedUsers = _commentedUsers
                                }
                                
                                // Optional hashtags
                                
                                if let _hashtags = p["hashtags"] as? [String] {
                                    post.hashtags = _hashtags
                                }
                                
                                posts.append(post)
                                
                            }
                            
                        }
                        
                        PostController.Instance.setRecommendedPosts(posts)
                        completion(true)
                        
                    } else {
                        
                        completion(false)
                        
                    }
                    
                    
                } else {
                    
                    completion(false)
                    
                }
                
        }
        
    }
    
    func getRecommendedPosts(completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPost)/recommended"
        
        print("Fetching user posts at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                var posts: [Post] = []
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let _posts = response.result.value as? [[String : AnyObject]] {
                        
                        for _p in _posts {
                                    
                            if  let _id = _p["_id"] as? String,
                                let _audio = _p["audio"] as? String,
                                let _createdAt = _p["createdAt"] as? String,
                                let _playCount = _p["play_count"] as? Int,
                                let _commentsCount = _p["comments_count"] as? Int,
                                let _title = _p["title"] as? String,
                                let _userObj = _p["user"] as? NSDictionary,
                                let _userId = _userObj["_id"] as? String,
                                let _name = _userObj["name"] as? String {
                                
                                // Create Meta
                                let _meta = Meta(createdAt: _createdAt)
                                
                                if let _updatedAt = _p["updatedAt"] as? String {
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
                                
                                // Optional hashtags
                                
                                if let _hashtags = _p["hashtags"] as? [String] {
                                    post.hashtags = _hashtags
                                }
                                
                                posts.append(post)
                                
                            }
                            
                        }
                        
                        PostController.Instance.setRecommendedPosts(posts)
                        completion(true)
                        
                    } else {
                        print("No posts.")
                        PostController.Instance.setRecommendedPosts([])
                        completion(false)
                    }
                    
                } else {
                    PostController.Instance.setRecommendedPosts([])
                    completion(false)
                }
        }
    }
    
    func incrementPost(id: String, completion: @escaping (_ success: Bool, _ play_count: Int?) -> Void) {
    
        let url = "\(self.baseURL)\(self.URLPost)/increment/\(id)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false, nil)
                    return
                }
                if let value = response.result.value as? Dictionary<String, Any> {
                    completion(response.response?.statusCode == 200, value["play_count"] as? Int)
                }else{
                    completion(response.response?.statusCode == 200, nil)
                }
                
        }
    }
    
    func deletePost(id: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPost)/\(id)"
        
        manager!.request(url, method: .delete, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                completion(response.response?.statusCode == 200)
                
        }
    }
    
    func getPost(postId: String, completion: @escaping (_ post: Post?) -> Void) {
        let url = "\(self.baseURL)\(self.URLPost)\(self.URLGetPostSuffix)/\(postId)"
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
        .responseJSON { (response) in
            if let err = response.result.error as NSError? {
                print("\n---Get Post Error---\n \(err.localizedDescription)\n")
                completion(nil)
                return
            }
            if let _ = response.result.value {
                print("Response: \(response.result.value!)")
            }
            if let dictPost = response.result.value {
                print(dictPost)
                completion(nil)
            }
        }
        
    }
    
    func getRecentPost(userId: String, completion: @escaping (_ post: [Post]?) -> Void) {
        let url = "\(self.baseURL)\(self.URLPost)\(self.URLGetRecentPostSuffix)/\(userId)"
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { (response) in
                if let err = response.result.error as NSError? {
                    print("\n---Get Recent Post Error---\n \(err.localizedDescription)\n")
                    completion(nil)
                    return
                }
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                if let dictPost = response.result.value {
                    print(dictPost)
                    completion(nil)
                }
        }
        
    }
    
    func getPostLikes(_ postId: String, skip : Int = 0, limit: Int = 100, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPost)\(self.URLGetPostLikesSuffix)/\(postId)?skip=\(skip)&limit=\(limit)"
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                var likes: [User] = []
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let _users = response.result.value as? [[String : AnyObject]] {
                        
                        for _u in _users {
                            
                            if let _userId = _u["_id"] as? String,
                                let _name = _u["name"] as? String {
                                // Create User
                                let _user = User(id: _userId, fullName: _name, email: "")
                                
                                if let _userPhoto = _u["photo"] as? String {
                                    _user.photo = _userPhoto
                                }
                                
                                if let _userFollowing = _u["following"] as? [AnyObject] {
                                    _user.following = _userFollowing
                                }
                                
                                if let _userFollowers = _u["followers"] as? [AnyObject] {
                                    _user.follower = _userFollowers
                                }
                                
                                if let _blocking = _u["blocking"] as? [AnyObject] {
                                    _user.blocking = _blocking
                                }
                                
                                if let _blockedBy = _u["blockedby"] as? [AnyObject] {
                                    _user.blockedby = _blockedBy
                                }
                                
                                if let _requested = _u["requested"] as? [AnyObject] {
                                    _user.requested = _requested
                                }
                                
                                if let _requesting = _u["requesting"] as? [AnyObject] {
                                    _user.requesting = _requesting
                                }
                                
                                if let _userDescription = _u["description"] as? String {
                                    _user.description = _userDescription
                                }
                                
                                likes.append(_user)
                            }
                            
                        }
                        
                        LikeController.Instance.setPostLikes(likes)
                        completion(true)
                        
                    } else {
                        print("No likes.")
                        LikeController.Instance.setPostLikes([])
                        completion(false)
                    }
                    
                } else {
                    LikeController.Instance.setPostLikes([])
                    completion(false)
                }
        }
        
    }
    
    func like(postId: String, completion: @escaping (_ success: Bool, _ like_description: String?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPost)\(self.URLLikeSuffix)/\(postId)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false, nil)
                    return
                }
                
                if let value = response.result.value as? Dictionary<String, Any> {
                    completion(response.response?.statusCode == 200, value["like_description"] as? String)
                }else{
                    completion(response.response?.statusCode == 200, nil)
                }
                
        }
        
    }
    
    func unlike(postId: String, completion: @escaping (_ success: Bool, _ like_description: String?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPost)\(self.URLUnlikeSuffix)/\(postId)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false, nil)
                    return
                }
                
                if let value = response.result.value as? Dictionary<String, Any> {
                    completion(response.response?.statusCode == 200, value["like_description"] as? String)
                }else{
                    completion(response.response?.statusCode == 200, nil)
                }
                
        }
        
    }
    
    func getTrendingHashtags(completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPost)\(self.URLGetTrendingHashtagsSuffix)"
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                if response.response?.statusCode == 200 {
                    if let _hashtags = response.result.value as? [String] {
                        PostController.Instance.setTrendingHashtags(_hashtags)
                        completion(true)
                    } else {
                        completion(false)
                    }
                    
                } else {
                    completion(false)
                }
                
        }
        
    }
    
    func getPostsFromHashtag(hashtag: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLPost)\(self.URLGetPostsFromHashtagSuffix)/\(hashtag.replacingOccurrences(of: "#", with: ""))"
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                var posts: [Post] = []
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let _posts = response.result.value as? NSArray {
                        
                        for p in _posts {
                            
                            if let _p = p as? NSDictionary,
                                let _id = _p["_id"] as? String,
                                let _audio = _p["audio"] as? String,
                                let _createdAt = _p["createdAt"] as? String,
                                let _playCount = _p["play_count"] as? Int,
                                let _commentsCount = _p["comments_count"] as? Int,
                                let _title = _p["title"] as? String,
                                let _userObj = _p["user"] as? NSDictionary,
                                let _userId = _userObj["_id"] as? String,
                                let _name = _userObj["name"] as? String {
                                
                                // Create Meta
                                let _meta = Meta(createdAt: _createdAt)
                                
                                if let _updatedAt = _p["updatedAt"] as? String {
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
                                
                                // Optional hashtags
                                
                                if let _hashtags = _p["hashtags"] as? [String] {
                                    post.hashtags = _hashtags
                                }
                                
                                posts.append(post)
                                
                            }
                            
                        }
                        
                        PostController.Instance.setHashtagPosts(posts)
                        completion(true)
                        
                    } else {
                        print("No posts.")
                        PostController.Instance.setHashtagPosts([])
                        completion(true)
                    }
                    
                } else {
                    PostController.Instance.setHashtagPosts([])
                    completion(false)
                }
                
        }
        
    }
    
}
