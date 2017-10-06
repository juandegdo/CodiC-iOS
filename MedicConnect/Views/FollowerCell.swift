//
//  FollowerCell.swift
//  MedicConnect
//
//  Created by Akio Yamadera on 6/20/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit

class FollowerCell : UITableViewCell {
    
    // Buttons
    @IBOutlet var btnFollowing: TVButton!
    @IBOutlet var btnRequested: TVButton!
    @IBOutlet var btnUnFollow: TVButton!
    
    // Labels
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblUserplays: UILabel!
    @IBOutlet var lblUserDescription: UILabel!
    
    // ImageViews
    @IBOutlet var imgUserPhoto: RadAvatar!
    
    var placeholderImage: UIImage?
    
    // Fonts
    let avatarFont = UIFont(name: "Avenir-Heavy", size: 15.0) as UIFont? ?? UIFont.systemFont(ofSize: 15.0)
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.placeholderImage = nil
    }
    
    // MARK: Set Data
    
    func setFollowData(user: User, showFollowingStatus: Bool = true) {
        
        // Customize button state
        
        guard let _user = UserController.Instance.getUser() as User? else {
            return
        }
        
        if((_user.requesting as! [User]).contains(where: { $0.id == user.id })) {
            self.btnRequested.isHidden = false
            self.btnFollowing.isHidden = true
            self.btnUnFollow.isHidden = true
        }else{
            self.btnFollowing.isHidden = (_user.id == user.id) || !showFollowingStatus || !(_user.following as! [User]).contains(where: { $0.id == user.id })
            self.btnUnFollow.isHidden = (_user.id == user.id) || !showFollowingStatus || (_user.following as! [User]).contains(where: { $0.id == user.id })
            self.btnRequested.isHidden = true
        }
        
        
        // Customize Avatar
        
//        if self.placeholderImage == nil {
//            self.placeholderImage = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: Constants.ColorOrange, text: user.getInitials(), font: avatarFont, size: CGSize(width: 55, height: 55))
//        }
        
        if let imgURL = URL(string: user.photo) as URL? {
            self.imgUserPhoto.af_setImage(withURL: imgURL)
//            self.imgUserPhoto.af_setImage(withURL: imgURL, placeholderImage: self.placeholderImage)
            
        } else {
            self.imgUserPhoto.image = nil
//            self.imgUserPhoto.image = self.placeholderImage
            
        }
        
        // Customize User Data
        
        self.lblUsername.text = user.fullName
        self.lblUserDescription.text = user.description
        
    }
    
    func toggleFollowData() {
        
        if self.btnFollowing.isHidden {
            self.btnFollowing.isHidden = false
            self.btnUnFollow.isHidden = true
        } else {
            self.btnFollowing.isHidden = true
            self.btnUnFollow.isHidden = false
        }
        
    }
}
