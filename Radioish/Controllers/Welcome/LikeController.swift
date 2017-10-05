//
//  LikeController.swift
//  Radioish
//
//  Created by Daniel Yang on 2017-08-09.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class LikeController {
    
    static let Instance = LikeController()
    
    fileprivate var postLikes: [User] = []
    
    //MARK: Likes
    
    func getPostLikes() -> [User] {
        return self.postLikes
    }
    
    func setPostLikes(_ likes: [User]) {
        self.postLikes = likes
    }
    
}
