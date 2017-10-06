//
//  SearchBroadcastCell.swift
//  MedicConnect
//
//  Created by alessandro on 1/2/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class SearchBroadcastCell: UICollectionViewCell {
    
    @IBOutlet var ivBanner: UIImageView!
    @IBOutlet var viewInfo: UIView!
    @IBOutlet var lblBroadcastname: UILabel!
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet weak var lblPlayCount: UILabel!
    
    func setBroadcastData(_ broadcast: User) {
        
        // Photo
        self.ivBanner.image = UIImage(named: broadcast.fullName)
        
        // Set Broadcast Label
        let broadcastNameFont: UIFont = UIFont(name: "Avenir-Book", size: 15.0) as UIFont? ?? UIFont.systemFont(ofSize: 15.0)
        let broadcastNameAttributes = [ NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName : broadcastNameFont ]
        let attributedBroadcastNameString: NSMutableAttributedString = NSMutableAttributedString(string: broadcast.description, attributes: broadcastNameAttributes)

        let playCountFont: UIFont = UIFont(name: "Avenir-Book", size: 12.0) as UIFont? ?? UIFont.systemFont(ofSize: 12.0)
        let playCountAttributes = [ NSForegroundColorAttributeName : UIColor(white: 1.0, alpha: 0.5), NSFontAttributeName : playCountFont ]
        let playCountString = NSMutableAttributedString(string: "\(broadcast.playCount) Plays", attributes: playCountAttributes)
        
        self.lblPlayCount.attributedText = playCountString
        self.lblBroadcastname.attributedText = attributedBroadcastNameString
        self.lblUsername.text = "\(broadcast.fullName)"

    }
}
