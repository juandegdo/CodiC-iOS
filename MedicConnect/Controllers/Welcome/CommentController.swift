//
//  PostController.swift
//  MedicConnect
//
//  Created by Akio Yamadera on 19/06/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Foundation

class CommentController {
    
    static let Instance = CommentController()
    
    fileprivate var comments: [Comment] = []
    
    //MARK: Comments
    
    func getComments() -> [Comment] {
        return self.comments.reversed()
    }
    
    func setComments(_ comments: [Comment]) {
        self.comments = comments.sorted(by: { $0.date < $1.date })
    }
    
}
