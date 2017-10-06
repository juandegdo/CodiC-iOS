//
//  PlaylistController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-08-15.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class PlaylistController {
    
    static let Instance = PlaylistController()
    
    fileprivate var playlistPosts: [Post] = []
    
    //MARK: Playlist Posts
    
    func getPlaylistPosts() -> [Post] {
        return self.playlistPosts
    }
    
    func setPlaylistPosts(_ posts: [Post]) {
        self.playlistPosts = posts
    }
    
}
