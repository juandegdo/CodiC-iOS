//
//  HistoryListCell.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2018-04-13.
//  Copyright © 2018 Loewen. All rights reserved.
//

import UIKit

class HistoryListCell: UITableViewCell {
    
    // ImageViews
    @IBOutlet var imgUserPhoto: RadAvatar!
    
    // Labels
    @IBOutlet var lblDoctorName: UILabel!
    @IBOutlet var lblDoctorLocation: UILabel!
    @IBOutlet var lblCallDate: UILabel!
    @IBOutlet var lblCallType: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    func setData(_ history: History) {
        // Set data
        self.lblDoctorName.text = "\(history.fromUser.fullName)"
        self.lblDoctorLocation.text = "\(history.fromUser.location)"
        self.lblCallType.text = "\(history.type.uppercased())"
        self.lblCallDate.text = history.getFormattedDate().replacingOccurrences(of: ",", with: "")
        
        self.imgUserPhoto.image = nil
        if let _user = history.fromUser as User? {
            if let imgURL = URL(string: _user.photo) as URL? {
                self.imgUserPhoto.af_setImage(withURL: imgURL)
            } else {
                self.imgUserPhoto.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                            text: _user.getInitials(),
                                                                                            font: UIFont(name: "Avenir-Book", size: 14)!,
                                                                                            size: CGSize(width: 30, height: 30))
            }
        }
    }
    
}
