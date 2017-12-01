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
    
    //MARK: Recommended posts
    
    func getRecommendedPosts() -> [Post] {
        return self.recommendedPosts.reversed()
    }
    
    func setRecommendedPosts(_ recommendedPosts: [Post]) {
        self.recommendedPosts = recommendedPosts
    }
    
    //MARK: Following posts
    
    func getFollowingPosts(type: String) -> [Post] {
        let posts = self.followingPosts.filter({(post: Post) -> Bool in
            return post.postType == type
        })
        
        return posts.reversed()
    }
    
    func setFollowingPosts(_ followingPosts: [Post]) {
        self.followingPosts = followingPosts
    }
    
    //MARK: Hashtag posts
    
    func getHashtagPosts() -> [Post] {
        return self.hashtagPosts.reversed()
    }
    
    func setHashtagPosts(_ hashtagPosts: [Post]) {
        self.hashtagPosts = hashtagPosts
    }
    
    //MARK: Trending hashtags
    
    func getTrendingHashtags() -> [String] {
        return self.trendingHashtags.reversed()
    }
    
    func setTrendingHashtags(_ trendingHashtags: [String]) {
        self.trendingHashtags = trendingHashtags
    }
    
}
