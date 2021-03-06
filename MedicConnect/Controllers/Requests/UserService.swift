//
//  UserService.swift
//  MedicConnect
//
//  Created by alessandro on 12/29/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import Alamofire
import Foundation

class UserService: BaseTaskController {
    
    static let Instance = UserService()
    
    var session: URLSession?
    var dataTask: URLSessionDataTask?
    var expectedContentLength = 0
    let MaximumImageSize: Int = 2097152
    
    func signup(_ user: User, completion: @escaping (_ success: Bool, _ message: String) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLSignUp)"
        
        let parameters = ["password" : user.password, "email" : user.email, "name" : user.fullName]
        
        simpleManager!.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false, "Please check your internet connection.")
                    return
                }
                
                if response.response?.statusCode == 200 {
                    if let _dic = response.result.value as? NSDictionary,
                        let _token = _dic["token"] as? String {
                        
                        UserDefaultsUtil.SaveToken(_token)
                        
                        UserService.Instance.getMe(completion: {
                            (user: User?) in
                            
                            if let _user = user as User? {
                                UserController.Instance.setUser(_user)
                                completion(true, "")
                            } else {
                                completion(false, "Inconsistent server response. Please try again later.")
                            }
                            
                        })
                    } else {
                        completion(false, "Inconsistent server response. Please try again later.")
                    }
                } else {
                    if let _dic = response.result.value as? NSDictionary,
                        let _message = _dic["error"] as? String {
                        completion(false, _message)
                    } else {
                        completion(false, "\(NSLocalizedString("Internal server error", comment: "comment")) \(String(describing: response.response?.statusCode)). \(NSLocalizedString("Please try again later.", comment: "comment"))")
                    }
                }
                
        }
    }
    
    func login(_ user: User, completion: @escaping (_ success: Bool, _ message: String) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLLogin)"
        
        let parameters = ["password" : user.password, "email" : user.email]
        
        simpleManager!.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false, "You aren't online!\nGet connected and try again.")
                    return
                }
                let code = response.response?.statusCode
                if code == 200 {
                    if let _dic = response.result.value as? NSDictionary,
                        let _token = _dic["token"] as? String {
                        
                        UserDefaultsUtil.SaveToken(_token)
                        
                        UserService.Instance.getMe(completion: {
                            (user: User?) in
                            
                            if let _user = user as User? {
                                UserController.Instance.setUser(_user)
                                completion(true, "")
                            } else {
                                completion(false, "Inconsistent server response. Please try again later.")
                            }
                            
                        })
                    } else {
                        completion(false, "Inconsistent server response. Please try again later.")
                    }
                } else if code == 403 {
                    completion(false, "Uh oh.. You've entered the wrong username or password. Try again.")
                } else {
                    if let _dic = response.result.value as? NSDictionary,
                        let _message = _dic["error"] as? String {
                        completion(false, _message)
                    } else {
                        completion(false, "Oh crap! Looks like our server is down. Hang tight.")
                    }
                    
                }
                
        }
    }
    
    func postUserImage(id: String, image: UIImage, completion: @escaping (_ success: Bool) -> Void) {
        
        guard let _url = URL(string: "\(self.baseURL)\(self.URLUser)") else {
            return
        }
        
        var urlRequest = URLRequest(url: _url)
        urlRequest.httpMethod = "PUT"
        urlRequest.timeoutInterval = TimeInterval(10 * 1000)
        
        self.manager!.upload(multipartFormData: { (multipartFormData) in
            
            if let _image = image as UIImage?,
                let _imageData = UIImageJPEGRepresentation(_image, 0.7){
                
                multipartFormData.append(_imageData, withName: "photo", fileName: "\(Date().timeIntervalSinceReferenceDate).jpg", mimeType: "image/jpeg")
            }
            
        }, with: urlRequest, encodingCompletion: { (result) in
            
            switch result {
            case .success(let upload, _, _):
                
                upload.responseJSON { response in

                    completion(response.response!.statusCode == 200)
                    
                }
                
            case .failure(let encodingError):
                print(encodingError)
                completion(false)
            }
            
        })
        
    }
    
    func editUser(user: User, completion: @escaping (_ success: Bool, _ message: String) -> Void) {
        
        guard let _url = URL(string: "\(self.baseURL)\(self.URLUser)") as URL? else {
            return
        }
        
        let parameters = ["name" : user.fullName, "description" : user.description, "phone" : user.phoneNumber]
        
        var urlRequest = URLRequest(url: _url)
        urlRequest.httpMethod = "PUT"
        urlRequest.timeoutInterval = TimeInterval(10 * 1000)
        
        self.manager!.upload(multipartFormData: { (multipartFormData) in
            
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
            
        }, with: urlRequest, encodingCompletion: { (result) in
            
            switch result {
            case .success(let upload, _, _):
                
                upload.responseJSON { response in
                    
                    if response.response?.statusCode == 200 {
                        completion(true, "")
                    } else {
                        if let _dic = response.result.value as? NSDictionary,
                            let _message = _dic["error"] as? String {
                            completion(false, _message)
                        } else {
                            completion(false, "\(NSLocalizedString("Internal server error", comment: "comment")) \(String(describing: response.response?.statusCode)). \(NSLocalizedString("Please try again later.", comment: "comment"))")
                        }
                    }
                    
                }
                
            case .failure(let encodingError):
                completion(false, "\(NSLocalizedString("Internal server error", comment: "comment")) \(encodingError.localizedDescription). \(NSLocalizedString("Please try again later.", comment: "comment"))")
            }
            
        })
    }
    
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (_ success: Bool, _ message: String) -> Void) {
        
        guard let _url = URL(string: "\(self.baseURL)\(self.URLUser)") as URL? else {
            return
        }
        
        let parameters = ["oldPassword" : currentPassword, "newPassword" : newPassword]
        
        var urlRequest = URLRequest(url: _url)
        urlRequest.httpMethod = "PUT"
        urlRequest.timeoutInterval = TimeInterval(10 * 1000)
        
        self.manager!.upload(multipartFormData: { (multipartFormData) in
            
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
            
        }, with: urlRequest, encodingCompletion: { (result) in
            
            switch result {
            case .success(let upload, _, _):
                
                upload.responseJSON { response in
                    
                    if response.response?.statusCode == 200 {
                        completion(true, "")
                    } else {
                        if let _dic = response.result.value as? NSDictionary,
                            let _message = _dic["error"] as? String {
                            completion(false, _message)
                        } else {
                            completion(false, "\(NSLocalizedString("Internal server error", comment: "comment")) \(String(describing: response.response?.statusCode)). \(NSLocalizedString("Please try again later.", comment: "comment"))")
                        }
                    }
                    
                }
                
            case .failure(let encodingError):
                completion(false, "\(NSLocalizedString("Internal server error", comment: "comment")) \(encodingError.localizedDescription). \(NSLocalizedString("Please try again later.", comment: "comment"))")
            }
            
        })
    }
    
    func forgotPassword(email: String, token: String, completion: @escaping (_ success: Bool, _ code: Int?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLForgetPassword)"
        
        let parameters = ["email" : email, "token": token]
        
        self.manager!.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                completion(response.response?.statusCode == 200, response.response?.statusCode)
                
        }
    }
    
    func updatePassword(token: String, new: String, completion: @escaping (_ success: Bool, _ code: Int?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUpdatePassword)/\(token)"
        
        let parameters = ["updatePassword" : new]
        
        self.manager!.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                completion(response.response?.statusCode == 200, response.response?.statusCode)
                
        }
    }
    
    func deleteAccount(completion: @escaping (_ success: Bool, _ message: String) -> Void) {
        
        guard let _url = URL(string: "\(self.baseURL)\(self.URLUser)") as URL? else {
            return
        }
        
        self.manager!.request(_url, method: .delete, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                if response.response?.statusCode == 200 {
                    completion(true, "")
                } else {
                    if let _dic = response.result.value as? NSDictionary,
                        let _message = _dic["error"] as? String {
                        completion(false, _message)
                    } else {
                        completion(false, "\(NSLocalizedString("Internal server error", comment: "comment")) \(String(describing: response.response?.statusCode)). \(NSLocalizedString("Please try again later.", comment: "comment"))")
                    }
                }
                
        }
    }
    
    func makePrivate(value: Bool, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = (value==true) ? "\(self.baseURL)\(self.URLUser)\(self.URLMakePrivateSuffix)" : "\(self.baseURL)\(self.URLUser)\(self.URLMakeUnprivateSuffix)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                print(response.result.value ?? "")
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                completion(response.response?.statusCode == 200)
                
        }
        
    }
    
    func setNotificationFilter(value: Int, completion: @escaping (_ success: Bool) -> Void) {
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLMakeNotiFilterSuffix)?filterValue=\(value)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                print(response.result.value ?? "")
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                completion(response.response?.statusCode == 200)
                
        }
        
    }
    
    func getMe(completion: @escaping (_ user: User?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)/me"
        
        self.manager!.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(nil)
                    return
                }
                                
                if response.response?.statusCode == 200 {
                    
                    if let _dic = response.result.value as? NSDictionary,
                        let _userId = _dic["_id"] as? String,
                        let _email = _dic["email"] as? String {
                        
                        let _name = _dic["name"] as? String ?? ""
                        
                        let _user = User(id: _userId, fullName: _name, email: _email)
                        
                        if let _userPhoto = _dic["photo"] as? String {
                            _user.photo = _userPhoto
                        }
                        
                        if let _userDescription = _dic["description"] as? String {
                            _user.description = _userDescription
                        }
                        
                        if let _isPrivate = _dic["isprivate"] as? Int {
                            _user.isprivate = (_isPrivate == 0) ? false : true
                        }
                        
                        if let _phone = _dic["phone"] as? String {
                            _user.phoneNumber = _phone
                        }
                        
                        if let _deviceToken = _dic["deviceToken"] as? String {
                            _user.deviceToken = _deviceToken
                        }
                        
                        if let _notificationfilter = _dic["notificationfilter"] as? Int {
                            _user.notificationfilter = _notificationfilter
                        }
                        
                        if let _posts = _dic["posts"] as? [[String : AnyObject]] {
                            
                            for p in _posts {
                                                            
                                if let _id = p["_id"] as? String,
                                    let _audio = p["audio"] as? String,
                                    let metaDic = p["meta"] as? [String : String],
                                    let _createdAt = metaDic["created_at"] as String?,
                                    let _playCount = p["play_count"] as? Int,
                                    let _commentsCount = p["comments_count"] as? Int,
                                    let _title = p["title"] as? String {
                                    
                                    // Create meta
                                    let _meta = Meta(createdAt: _createdAt)
                                    
                                    if let _updatedAt = metaDic["updated_at"] as String? {
                                        _meta.updatedAt = _updatedAt
                                    }
                                    
                                    let post = Post(id: _id, audio: _audio, meta: _meta, playCount: _playCount, commentsCount: _commentsCount, title: _title, description: "", user: _user)
                                    
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
                                    
                                    _user.posts.append(post)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _blockedby = _dic["blockedby"] as? [[String : AnyObject]] {
                            
                            for f in _blockedby {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let blockedby = User(id: _id, fullName: _name)
                                    
                                    if let _description = f["description"] as? String {
                                        blockedby.description = _description
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        blockedby.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        blockedby.photo = _photo
                                    }
                                    
                                    _user.blockedby.append(blockedby)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _blocking = _dic["blocking"] as? [[String : AnyObject]] {
                            
                            for f in _blocking {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let blocking = User(id: _id, fullName: _name)
                                    
                                    if let _description = f["description"] as? String {
                                        blocking.description = _description
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        blocking.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        blocking.photo = _photo
                                    }
                                    
                                    _user.blocking.append(blocking)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _following = _dic["following"] as? [[String : AnyObject]] {
                            
                            for f in _following {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let follow = User(id: _id, fullName: _name)
                                    
                                    if let _description = f["description"] as? String {
                                        follow.description = _description
                                    }
                                    if let _private = f["isprivate"] as? Int {
                                        follow.isprivate = (_private == 0) ? false : true
                                    }
                                    if let _photo = f["photo"] as? String {
                                        follow.photo = _photo
                                    }
                                    
                                    if let _blocking = _user.blocking as? [User] {
                                        let isBlocked = _blocking.contains(where: { (user) -> Bool in
                                            return (user.id == _id)
                                        })
                                        if isBlocked {
                                            continue
                                        }
                                    }
                                    _user.following.append(follow)
                                }
                                
                            }
                            
                        }
                        
                        if let followers = _dic["followers"] as? [[String : AnyObject]] {
                            
                            for f in followers {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let follow = User(id: _id, fullName: _name)
                                    
                                    if let _description = f["description"] as? String {
                                        follow.description = _description
                                    }
                                    if let _private = f["isprivate"] as? Int {
                                        follow.isprivate = (_private == 0) ? false : true
                                    }
                                    if let _photo = f["photo"] as? String {
                                        follow.photo = _photo
                                    }
                                    
                                    _user.follower.append(follow)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _requested = _dic["requested"] as? [[String : AnyObject]] {
                            
                            for f in _requested {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let request = User(id: _id, fullName: _name)
                                    
                                    if let _description = f["description"] as? String {
                                        request.description = _description
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        request.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        request.photo = _photo
                                    }
                                    
                                    _user.requested.append(request)
                                    
                                }
                                
                            }
                            
                        }
                        if let _requesting = _dic["requesting"] as? [[String : AnyObject]] {
                            
                            for f in _requesting {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let request = User(id: _id, fullName: _name)
                                    
                                    if let _description = f["description"] as? String {
                                        request.description = _description
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        request.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        request.photo = _photo
                                    }
                                    
                                    _user.requesting.append(request)
                                    
                                }
                                
                            }
                            
                        }
                        
                        UserController.Instance.setUser(_user)
                        completion(_user)
                        
                    } else {
                        completion(nil)
                    }
                    
                } else {
                    completion(nil)
                }
                
        }
    }
    
    func getUser(forId: String, completion: @escaping (_ user: User?) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)/id/\(forId)"
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(nil)
                    return
                }
                                
                if response.response?.statusCode == 200 {
                    
                    if let _dic = response.result.value as? NSDictionary,
                        let _userId = _dic["_id"] as? String,
                        let _email = _dic["email"] as? String {
                        
                        let _name = _dic["name"] as? String ?? ""
                        
                        let _user = User(id: _userId, fullName: _name, email: _email)
                        
                        if let _userPhoto = _dic["photo"] as? String {
                            _user.photo = _userPhoto
                        }
                        
                        if let _userDescription = _dic["description"] as? String {
                            _user.description = _userDescription
                        }
                        
                        if let _isPrivate = _dic["isprivate"] as? Int {
                            _user.isprivate = (_isPrivate == 0) ? false : true
                        }
                        
                        if let _posts = _dic["posts"] as? [[String : AnyObject]] {
                            
                            for p in _posts {
                                
                                if let _id = p["_id"] as? String,
                                    let _audio = p["audio"] as? String,
                                    let metaDic = p["meta"] as? [String : String],
                                    let _createdAt = metaDic["created_at"] as String?,
                                    let _playCount = p["play_count"] as? Int,
                                    let _commentsCount = p["comments_count"] as? Int,
                                    let _title = p["title"] as? String {
                                    
                                    // Create meta
                                    let _meta = Meta(createdAt: _createdAt)
                                    
                                    if let _updatedAt = metaDic["updated_at"] as String? {
                                        _meta.updatedAt = _updatedAt
                                    }
                                    
                                    let post = Post(id: _id, audio: _audio, meta: _meta, playCount: _playCount, commentsCount: _commentsCount, title: _title, description: "", user: _user)
                                    
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
                                    
                                    _user.posts.append(post)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _blockedBy = _dic["blockedby"] as? [AnyObject] {
                            _user.blockedby = _blockedBy
                        }
                        
                        if let _following = _dic["following"] as? [[String : AnyObject]] {
                            
                            for f in _following {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let follow = User(id: _id, fullName: _name)
                                    
                                    if let _description = f["description"] as? String {
                                        follow.description = _description
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        follow.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        follow.photo = _photo
                                    }
                                    
                                    _user.following.append(follow)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let followers = _dic["followers"] as? [[String : AnyObject]] {
                            
                            for f in followers {
                                
                                if let _id = f["_id"] as? String,
                                    let _name = f["name"] as? String {
                                    
                                    let follow = User(id: _id, fullName: _name)
                                    
                                    if let _description = f["description"] as? String {
                                        follow.description = _description
                                    }
                                    
                                    if let _private = f["isprivate"] as? Int {
                                        follow.isprivate = (_private == 0) ? false : true
                                    }
                                    
                                    if let _photo = f["photo"] as? String {
                                        follow.photo = _photo
                                    }
                                    
                                    _user.follower.append(follow)
                                    
                                }
                                
                            }
                            
                        }
                        
                        if let _blocking = _dic["blocking"] as? [AnyObject] {
                            _user.blocking = _blocking
                        }
                        
                        
                        if let _requested = _dic["requested"] as? [AnyObject] {
                            _user.requested = _requested
                        }
                        if let _requesting = _dic["requesting"] as? [AnyObject] {
                            _user.requesting = _requesting
                        }
                        
                        completion(_user)
                        
                    } else {
                        print("Null 1")
                        completion(nil)
                    }
                    
                } else {
                    print("Null 2")
                    completion(nil)
                }
                
                
        }
    }
    
    func getAll(name: String, completion: @escaping (_ success: BaseTaskController.Response) -> Void) {
        
        //TODO: Discuss best practice for page and limit with backend dev.
//        if  let _me = UserController.Instance.getUser() as User?,
        
        guard let _ = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) as String? else {
            return
        }
        
        let url = "\(self.baseURL)\(self.URLUser)/all?skip=0&limit=100"
        
        var users: [User] = []
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(BaseTaskController.Response.noConnection)
                    return
                }
                
                if response.response?.statusCode == 200 {
                    
                    if let _dicArray = response.result.value as? NSArray {
                        for d in _dicArray {
                            
                            if let _dic = d as? NSDictionary,
                                let _id = _dic["_id"] as? String,
                                let _name = _dic["name"] as? String {
                                
                                let _user = User(id: _id, fullName: _name)
                                
                                if let _userPhoto = _dic["photo"] as? String {
                                    _user.photo = _userPhoto
                                }
                                
                                if let _userFollowing = _dic["following"] as? [AnyObject] {
                                    _user.following = _userFollowing
                                }
                                
                                if let _userFollowers = _dic["followers"] as? [AnyObject] {
                                    _user.follower = _userFollowers
                                }
                                
                                if let _blocking = _dic["blocking"] as? [AnyObject] {
                                    _user.blocking = _blocking
                                }
                                
                                if let _blockedBy = _dic["blockedby"] as? [AnyObject] {
                                    _user.blockedby = _blockedBy
                                }
                                
                                if let _requested = _dic["requested"] as? [AnyObject] {
                                    _user.requested = _requested
                                }
                                
                                if let _requesting = _dic["requesting"] as? [AnyObject] {
                                    _user.requesting = _requesting
                                }
                                
                                if let _userDescription = _dic["description"] as? String {
                                    _user.description = _userDescription
                                }
                                
                                if let _isprivate = _dic["isprivate"] as? Int {
                                    _user.isprivate = (_isprivate == 0) ? false : true
                                }
                                
                                users.append(_user)
                                
                            }
                        }
                        
                        UserController.Instance.setUsers(users)
                        completion(BaseTaskController.Response.success)
                        
                    } else {
                        completion(BaseTaskController.Response.failure)
                    }
                    
                } else {
                    completion(BaseTaskController.Response.failure)
                }
        }
    }
    
    func getTimeline(completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)/timeline"
        
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
                    
                    if let _posts = response.result.value as? NSArray {
                                
                        for p in _posts {
                            
                            if let _p = p as? NSDictionary,
                                let _id = _p["_id"] as? String,
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
                            
                        PostController.Instance.setFollowingPosts(posts)
                        completion(true)
                        
                    } else {
                        print("No posts.")
                        PostController.Instance.setFollowingPosts([])
                        completion(false)
                    }
                    
                } else {
                    PostController.Instance.setFollowingPosts([])
                    completion(false)
                }
        }
    }
    
    func getRecommendedUsers(completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)/recommended"
        
        print("Fetching user posts at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                var users: [User] = []
                
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
                                
                                users.append(_user)
                            }
                            
                        }
                        
                        UserController.Instance.setRecommedendUsers(users)
                        completion(true)
                        
                    } else {
                        print("No posts.")
                        UserController.Instance.setRecommedendUsers([])
                        completion(false)
                    }
                    
                } else {
                    UserController.Instance.setRecommedendUsers([])
                    completion(false)
                }
        }
    }
    
    func getPromotedUsers(completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)/getpromotedcontent"
        
        print("Fetching promoted content at \(url)")
        
        manager!.request(url, method: .get, parameters: nil, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    completion(false)
                    return
                }
                
                var users: [User] = []
                
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
                                
                                if let _playCount = _u["play_count"] as? Int {
                                    _user.playCount = _playCount
                                }
                                
                                users.append(_user)
                            }
                            
                        }
                        
                        let sortedUsers = users.sorted(by: { $0.fullName < $1.fullName })
                        
                        UserController.Instance.setPromotedUsers(sortedUsers)
                        completion(true)
                        
                    } else {
                        print("No posts.")
                        UserController.Instance.setPromotedUsers([])
                        completion(false)
                    }
                    
                } else {
                    UserController.Instance.setPromotedUsers([])
                    completion(false)
                }
        }
    }
    
    func block(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLBlockSuffix)/\(userId)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func unblock(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLUnblockSuffix)/\(userId)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func acceptRequest(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLAcceptRequestSuffix)/\(userId)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func declineRequest(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLDeclineRequestSuffix)/\(userId)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func follow(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLFollowSuffix)/\(userId)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func unfollow(userId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLUnfollowSuffix)/\(userId)"
        
        manager!.request(url, method: .put, parameters: nil, encoding: URLEncoding.default)
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
    
    func putDeviceToken(deviceToken: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLUser)\(self.URLDeviceToken)"
        let parameter = ["deviceToken": deviceToken]
        manager!.request(url, method: .put, parameters: parameter, encoding: URLEncoding.default)
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
    
    func report(from: String, subject: String, msgbody: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLReport)"
        let parameter = ["from": from, "subject": subject, "text": msgbody]
        manager!.request(url, method: .post, parameters: parameter, encoding: URLEncoding.default)
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
    
}
