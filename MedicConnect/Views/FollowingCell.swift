//
//  FollowingCell.swift
//  MedicConnect
//
//  Created by alessandro on 11/27/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit

class FollowingCell: UITableViewCell {
    
    // Buttons
    @IBOutlet var btnFavorite: TVButton!
    @IBOutlet var btnMessage: TVButton!
    @IBOutlet var btnAction: TVButton!
    
    // Labels
    @IBOutlet var lblUserName: UILabel!
    @IBOutlet var lblUserLocation: UILabel!
    @IBOutlet var lblUserTitle: UILabel!
    
    // ImageViews
    @IBOutlet var imgUserPhoto: RadAvatar!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    // MARK: Set Data
    
    func setFollowData(user: User, showFollowingStatus: Bool = true) {
        
        guard let _user = UserController.Instance.getUser() as User? else {
            return
        }
        
        if let imgURL = URL(string: user.photo) as URL? {
            self.imgUserPhoto.af_setImage(withURL: imgURL)
        } else {
            self.imgUserPhoto.image = nil
        }
        
        // Customize User Data
        self.lblUserName.text = user.fullName
//        self.lblUserTitle.text = user.title
//        self.lblUserLocation.text = user.location
        
    }
    
}
