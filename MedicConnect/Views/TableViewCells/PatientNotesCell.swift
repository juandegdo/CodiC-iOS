//
//  PatientNotesCell.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-11-20.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class PatientNotesCell: UITableViewCell {

    // ImageViews
    @IBOutlet var imgUserAvatar: UIImageView!
    @IBOutlet var ivProgressCircle: UIImageView!
    
    // Buttons
    @IBOutlet var btnSynopsis: UIButton!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnBackward: UIButton!
    @IBOutlet var btnForward: UIButton!
    
    // Labels
    @IBOutlet var lblBroadcast: UILabel!
    @IBOutlet var lblDescription: ExpandableLabel!
    @IBOutlet var lblDoctorName: UILabel!
    @IBOutlet var lblDate: UILabel!
    @IBOutlet var lblElapsedTime: UILabel!
    @IBOutlet var lblDuration: UILabel!
    
    // Slider
    @IBOutlet weak var playSlider: PlaySlider!
    
    // Constraints
    @IBOutlet var constOfLblDescriptionHeight: NSLayoutConstraint!
    @IBOutlet var constOfImageAvatarBottom: NSLayoutConstraint!
    
    var postDescription: String = ""
    
    // Expand/Collpase
    var isExpanded:Bool = false {
        didSet {
            if !isExpanded {
                self.clipsToBounds = true
                
                self.lblDescription.numberOfLines = 1
                self.lblDescription.shouldExpand = true
                self.lblDescription.text = self.postDescription
                self.lblDescription.collapsed = true
                
                self.constOfImageAvatarBottom.constant = 20
                self.constOfLblDescriptionHeight.constant = 18
                self.btnPlay.isHidden = true
                self.btnBackward.isHidden = true
                self.btnForward.isHidden = true
                self.lblElapsedTime.isHidden = true
                self.lblDuration.isHidden = true
                self.playSlider.isHidden = true
                
            } else {
                self.clipsToBounds = false
                
                let constRect = CGSize(width: self.lblDescription.bounds.size.width, height: .greatestFiniteMagnitude)
                let boundBox = self.postDescription.boundingRect(with: constRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self.lblDescription.font], context: nil)
                self.constOfLblDescriptionHeight.constant = ceil(boundBox.height)
                self.lblDescription.shouldCollapse = true
                self.lblDescription.text = self.postDescription
                self.lblDescription.collapsed = false
                
                self.constOfImageAvatarBottom.constant = 65 + 20
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                    self.btnPlay.isHidden = false
                    self.btnBackward.isHidden = false
                    self.btnForward.isHidden = false
                    self.lblElapsedTime.isHidden = false
                    self.lblDuration.isHidden = false
                    self.playSlider.isHidden = false
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Slider
        self.playSlider.setThumbImage(UIImage(named: "icon_play_slider_pin"), for: .normal)
        self.playSlider.setThumbImage(UIImage(named: "icon_play_slider_pin"), for: .highlighted)
        self.playSlider.setThumbImage(UIImage(named: "icon_play_slider_pin"), for: .selected)
        
        // Spinning Circle
        self.ivProgressCircle.loadGif(name: "progress_circle")
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.lblDescription.collapsed = true
        self.lblDescription.text = nil
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        
    }
    
    func setData(post: Post) {
        // Set Patient Note Info
        self.lblBroadcast.text = post.title
        self.lblDoctorName.text = post.user.fullName
        self.lblDate.text = post.getFormattedDate()
        self.postDescription = post.descriptions
        
        // Customize Avatar
        self.imgUserAvatar.image = nil
        if let imgURL = URL(string: post.user.photo) as URL? {
            self.imgUserAvatar.af_setImage(withURL: imgURL)
        }
        
        if post.orderNumber == "" {
            self.btnSynopsis.isHidden = true
            self.ivProgressCircle.isHidden = true
            
        } else {
            self.btnSynopsis.isHidden = false
            
            if post.transcriptionUrl == "" {
                self.btnSynopsis.setImage(UIImage.init(named: "icon_transcription_inactive"), for: .normal)
                self.ivProgressCircle.isHidden = false
            } else {
                self.btnSynopsis.setImage(UIImage.init(named: "icon_transcription_active"), for: .normal)
                self.ivProgressCircle.isHidden = true
            }
        }
    }
    
}
