//
//  SearchPeopleCell.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-08-09.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class SearchPeopleCell: UITableViewCell {
    
    // Labels
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblUserDescription: UILabel!
    @IBOutlet var lblUserplays: UILabel!
    
    // ImageViews
    @IBOutlet var imgUserPhoto: RadAvatar!
    
    var placeholderImage: UIImage?
    
    // Fonts
    let avatarFont = UIFont(name: "Avenir-Heavy", size: 15.0) as UIFont? ?? UIFont.systemFont(ofSize: 15.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.placeholderImage = nil
    }
    
    // MARK: Set Data
    
    func setPeopleData(user: User) {
        
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
    
}
