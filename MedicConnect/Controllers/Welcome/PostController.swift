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
        return self.recommendedPosts.sorted(by: {$0.meta.createdAt > $1.meta.createdAt} )
    }
    
    func setRecommendedPosts(_ recommendedPosts: [Post]) {
        self.recommendedPosts = recommendedPosts
    }
    
    //MARK: Following posts
    
    func getFollowingPosts() -> [Post] {
        return self.followingPosts.sorted(by: {$0.meta.createdAt > $1.meta.createdAt} )
    }
    
    func setFollowingPosts(_ followingPosts: [Post]) {
        self.followingPosts = followingPosts
    }
    
    //MARK: Hashtag posts
    
    func getHashtagPosts() -> [Post] {
        return self.hashtagPosts.sorted(by: {$0.meta.createdAt > $1.meta.createdAt} )
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
    
}
