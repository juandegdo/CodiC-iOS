//
//  BaseTaskController.swift
//  Radioish
//
//  Created by alessandro on 12/29/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import Foundation
import Alamofire

class BaseTaskController {
    // Production
//    let baseURL = "http://sample-env.cku2twjvua.us-east-2.elasticbeanstalk.com/radioish_back/api"
    // Development
    let baseURL = "http://radioish-dev.us-east-2.elasticbeanstalk.com/radioish_back/api"
    
    let URLSignUp = "/signup"
    let URLLogin = "/login"
    let URLUser = "/user"
    let URLPost = "/post"
    let URLComment = "/comment"
    let URLNotification = "/notification"
    let URLPlaylist = "/playlist"
    let URLReport = "/report"
    let URLSearch = "/search"
    
    let URLForgetPassword = "/forgotPassword"
    let URLUpdatePassword = "/resetPassword"
    
    let URLFollowSuffix = "/follow"
    let URLUnfollowSuffix = "/unfollow"
    let URLDeviceToken = "/deviceToken"
    
    let URLLikeSuffix = "/like"
    let URLUnlikeSuffix = "/unlike"
    
    let URLBlockSuffix = "/block"
    let URLUnblockSuffix = "/unblock"
    
    let URLMakePrivateSuffix = "/makeprivate"
    let URLMakeUnprivateSuffix = "/makeunprivate"
    
    let URLAcceptRequestSuffix = "/accept"
    let URLDeclineRequestSuffix = "/decline"
    
    let URLGetPostSuffix = "/getpost"
    let URLGetRecentPostSuffix = "/getrecentpost"
    let URLGetPostLikesSuffix = "/getpostlikes"
    
    let URLMakeNotiFilterSuffix = "/setnotificationfilter"
    
    let URLAddToPlaylistSuffix = "/addtoplaylist"
    let URLRemovePlaylistUserSuffix = "/removeplaylistuser"
    let URLGetPlaylistSuffix = "/getplaylist"
    
    let URLGetTrendingHashtagsSuffix = "/gettrendinghashtags"
    let URLGetPostsFromHashtagSuffix = "/getpostsfromhashtag"
    
    var simpleManager: SessionManager?
    var manager: SessionManager?
    
    enum Response {
        case success
        case failure
        case noConnection
    }
    
    init() {
        DataRequest.addAcceptableImageContentTypes(["image/jpg"])
        self.configureInstance(UserDefaultsUtil.LoadToken())
    }

    func configureInstance(_ token: String) {
        
        let bearer = "Bearer \(token)"
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization" : bearer, "user-agent" : UIDevice.current.identifierForVendor!.uuidString.sha1()]
        self.manager = SessionManager(configuration: configuration)
        
        let simpleConfiguration = URLSessionConfiguration.default
        simpleConfiguration.httpAdditionalHeaders = ["user-agent" : UIDevice.current.identifierForVendor!.uuidString.sha1()]
        self.simpleManager = SessionManager(configuration: simpleConfiguration)
        
    }
}
