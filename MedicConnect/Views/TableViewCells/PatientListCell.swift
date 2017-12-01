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
        
        self.lblDescription.collapsed = true
        self.lblDescription.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    func setData(_ patient: Patient) {
        // Set data
        self.lblPatientName.text = "\(patient.name) #\(patient.patientNumber)"
        self.lblDoctorName.text = "Dr. \(patient.user.fullName)"
        self.lblDate.text = patient.getFormattedDate().replacingOccurrences(of: ",", with: "")
        
        self.imgUserPhoto.image = nil
        if let _user = patient.user as User? {
            if let imgURL = URL(string: _user.photo) as URL? {
                self.imgUserPhoto.af_setImage(withURL: imgURL)
            }
        }
    }

}
