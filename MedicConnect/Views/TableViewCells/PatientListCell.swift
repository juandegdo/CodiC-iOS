//
//  PatientListCell.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-31.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class PatientListCell: UITableViewCell {

    // ImageViews
    @IBOutlet var imgUserPhoto: RadAvatar!
    
    // Buttons
    @IBOutlet var btnAction: TVButton!
    
    // Constraints
    @IBOutlet var constOfLblDescriptionHeight: NSLayoutConstraint!
    
    // Labels
    @IBOutlet var lblPatientName: UILabel!
    @IBOutlet var lblDescription: ExpandableLabel!
    @IBOutlet var lblDoctorName: UILabel!
    @IBOutlet var lblDate: UILabel!

    var placeholderImage: UIImage?
    
    // Descriptioin Expand/Collpase
    var showFullDescription:Bool = false {
        didSet {
            if !showFullDescription {
                self.constOfLblDescriptionHeight.constant = 18
            } else {
                let constraintRect = CGSize(width: self.lblDescription.bounds.size.width, height: .greatestFiniteMagnitude)
                let boundingBox = self.lblDescription.text?.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: self.lblDescription.font], context: nil)
                
                self.constOfLblDescriptionHeight.constant = (boundingBox?.height)!
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.placeholderImage = nil
        
        self.lblDescription.collapsed = true
        self.lblDescription.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    func setData(data: [String: String]) {
        // Set data
        self.lblPatientName.text = data["patientName"]
        self.lblDoctorName.text = data["doctorName"]
        self.lblDate.text = data["date"]
        
        self.imgUserPhoto.image = nil
        if let imgURL = URL(string: data["photoURL"]!) as URL? {
            self.imgUserPhoto.af_setImage(withURL: imgURL)
        } else {
            self.imgUserPhoto.image = nil
        }
    }

}
