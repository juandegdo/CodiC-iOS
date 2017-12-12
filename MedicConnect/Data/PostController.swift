//
//  PostController.swift
//  MedicConnect
//
//  Created by Alessandro Zoffoli on 23/03/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Foundation

class PostController {
    
    static let Instance = PostController()
    
    fileprivate var recommendedPosts: [Post] = []
    fileprivate var followingPosts: [Post] = []
    fileprivate var hashtagPosts: [Post] = []
    fileprivate var trendingHashtags: [String] = []
    fileprivate var patientNotes: [Post] = []
    
    //MARK: Recommended posts
    
    func getRecommendedPosts() -> [Post] {
        return self.recommendedPosts
    }
    
    func setRecommendedPosts(_ recommendedPosts: [Post]) {
        self.recommendedPosts = recommendedPosts
    }
    
    //MARK: Following posts
    
    func getFollowingPosts(type: String) -> [Post] {
        let posts = self.followingPosts.filter({(post: Post) -> Bool in
            return post.postType == type
        })
        
        return posts
    }
    
    func setFollowingPosts(_ followingPosts: [Post]) {
        self.followingPosts = followingPosts
    }
    
    //MARK: Hashtag posts
    
    func getHashtagPosts() -> [Post] {
        return self.hashtagPosts
    }
    
    func setHashtagPosts(_ hashtagPosts: [Post]) {
        self.hashtagPosts = hashtagPosts
    }
    
    //MARK: Trending hashtags
    
    func getTrendingHashtags() -> [String] {
        return self.trendingHashtags
    }
    
    func setTrendingHashtags(_ trendingHashtags: [String]) {
        self.trendingHashtags = trendingHashtags
    }
    
    //MARK: Patient Notes
    
    func getPatientNotes() -> [Post] {
        return self.patientNotes
    }
    
    func setPatientNotes(_ patientNotes: [Post]) {
        self.patientNotes = patientNotes
    }
    
}
