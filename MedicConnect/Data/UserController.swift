//
//  UserController.swift
//  MedicConnect
//
//  Created by alessandro on 2/23/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Foundation

class UserController {
    
    static let Instance = UserController()
    fileprivate var user: User?
    fileprivate var users: [User] = []
    fileprivate var recommendedUsers: [User] = []
    fileprivate var promotedUsers: [User] = []
    fileprivate var avatarImg : UIImage?
    fileprivate var deviceToken: String?
    
    // User Avatar
    func getAvatarImg() -> UIImage? {
        return self.avatarImg
    }
    
    func setAvatarImg(_ img: UIImage?) {
        self.avatarImg = img
    }
    
    
    // User
    
    func getUser() -> User! {
        return self.user
    }
    
    func setUser(_ user: User) {
        self.user = user
    }
    
    func eraseUser() {
        user = nil
    }
    
    /**
     * Tries to delete a post from the property array and returns operation result
     */
    func deletePost(id: String) -> Bool {
        
        if let _user = self.user as User? {
            
            for i in 0..<_user.posts.count {
                if id == user?.posts[i].id {
                    _user.posts.remove(at: i)
                    return true
                }
            }
            
            return false
            
        } else {
            
            return false
            
        }
    }
    
    // Recommended Users
    func getRecommendedUsers() -> [User] {
        return self.recommendedUsers
    }
    
    func setRecommedendUsers(_ users: [User]) {
        print("Set \(users.count) users.")
        self.recommendedUsers = users
    }
    
    // Promoted Users
    func getPromotedUsers() -> [User] {
        return self.promotedUsers
    }
    
    func setPromotedUsers(_ users: [User]) {
        print("Set \(users.count) users.")
        self.promotedUsers = users
    }
    
    // Users
    
    func getUsers() -> [User] {
        return self.users
    }
    
    func setUsers(_ users: [User]) {
        print("Set \(users.count) users.")
        self.users = users
    }
    
    func searchForUsers(string: String) -> [User] {
        
        var result: [User] = []
        
        if string == "" {
            return result
        }
        
        let blocking = self.getUser().blocking as! [User]
        let blockedby = self.getUser().blockedby as! [User]
        
        for u in self.users {
            
            if blocking.contains(where: { $0.id == u.id }) {
                continue
            }
            if blockedby.contains(where: { $0.id == u.id }) {
                continue
            }
            
            let lowercasedUsername = u.fullName.uppercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            for n in lowercasedUsername.components(separatedBy: " ") {
                if (n.hasPrefix(string.uppercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))) {
                    result.append(u)
                    break
                }
            }
        }

        return result
        
    }
    
    // User Device Token
    func getDeviceToken() -> String? {
        return self.deviceToken
    }
    
    func setDeviceToken(_ token: String) {
        self.deviceToken = token
    }
    
    // Places
    func searchForPlaces(string: String) -> [String] {
        return []
    }
    
}
