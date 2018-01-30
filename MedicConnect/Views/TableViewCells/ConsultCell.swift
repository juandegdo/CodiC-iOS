//
//  ConsultCell.swift
//  MedicConnect
//
//  Created by alessandro on 11/26/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import AlamofireImage
import Sheriff
import TTTAttributedLabel

class ConsultCell: UITableViewCell {
    
    // ImageViews
    @IBOutlet var imgUserAvatar: UIImageView!
    @IBOutlet var ivProgressCircle: UIImageView!
    
    // Buttons
    @IBOutlet var btnSynopsis: UIButton!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnBackward: UIButton!
    @IBOutlet var btnForward: UIButton!
    
    // Constraints
    @IBOutlet var constOfLblDescriptionHeight: NSLayoutConstraint!
    @IBOutlet var constOfLblDateBottom: NSLayoutConstraint!
    @IBOutlet var constOfTxtVHashtagsHeight: NSLayoutConstraint!
    
    // Labels
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblBroadcast: UILabel!
    @IBOutlet var lblDescription: ExpandableLabel!
    @IBOutlet var lblDate: UILabel!
    @IBOutlet var lblElapsedTime: UILabel!
    @IBOutlet var lblDuration: UILabel!
    
    // TextView
    @IBOutlet weak var txtVHashtags: UITextView!
    
    // Slider
    @IBOutlet weak var playSlider: PlaySlider!
    
    var postDescription: String = ""
    
    // Expand/Collpase
    var isExpanded: Bool = false {
        didSet {
            if !isExpanded {
                self.clipsToBounds = true
                
                self.lblDescription.numberOfLines = 1
                self.lblDescription.shouldExpand = true
                self.lblDescription.text = self.postDescription
                self.lblDescription.collapsed = true
                
                self.constOfLblDateBottom.constant = 15
                self.constOfLblDescriptionHeight.constant = 18
                self.txtVHashtags.isHidden = true
                self.btnPlay.isHidden = true
                self.btnBackward.isHidden = true
                self.btnForward.isHidden = true
                self.lblElapsedTime.isHidden = true
                self.lblDuration.isHidden = true
                self.playSlider.isHidden = true
                
            } else {
                self.clipsToBounds = false
                
                let constRect = CGSize(width: Constants.ScreenWidth - 117, height: .greatestFiniteMagnitude)
                let boundBox = self.postDescription.boundingRect(with: constRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self.lblDescription.font], context: nil)
                self.constOfLblDescriptionHeight.constant = ceil(boundBox.height)
                self.lblDescription.shouldCollapse = true
                self.lblDescription.text = self.postDescription
                self.lblDescription.collapsed = false
                
                let constraintRect = CGSize(width: self.txtVHashtags.bounds.size.width, height: .greatestFiniteMagnitude)
                let boundingBox = self.txtVHashtags.text == "" ? CGRect.zero : self.txtVHashtags.text!.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self.txtVHashtags.font!], context: nil)
                
                self.constOfTxtVHashtagsHeight.constant = self.txtVHashtags.text == "" ? ceil(boundingBox.height) : ceil(boundingBox.height) + 16.0
                self.constOfLblDateBottom.constant = self.constOfTxtVHashtagsHeight.constant + 17 + 65
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                    self.lblDescription.numberOfLines = 0
                    
                    self.txtVHashtags.isHidden = false
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
        
    func setData(post: Post) {
        
        // Set core data
        self.lblUsername.text = "\(post.user.fullName)"
        
        // Set Broadcast Label
        self.lblBroadcast.text = "\(post.patientName) \(post.patientPHN)"
        
        // Set date label
        self.lblDate.text = post.getFormattedDate()
        
        // Set description
        self.postDescription = post.descriptions
        
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
        
        // Set hashtags textview
        self.txtVHashtags.text = post.hashtags.count > 0 ? post.hashtags.joined(separator: " ") : ""
                
        // Customize Avatar
        self.imgUserAvatar.image = nil
        if let imgURL = URL(string: post.user.photo) as URL? {
            self.imgUserAvatar.af_setImage(withURL: imgURL)
        }
        
    }
    
}
