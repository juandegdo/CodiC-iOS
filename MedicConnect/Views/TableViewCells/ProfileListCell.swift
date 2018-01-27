//
//  ProfileListCell.swift
//  MedicConnect
//
//  Created by alessandro on 11/27/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import SwiftGifOrigin

class ProfileListCell: UITableViewCell {
    
    // Buttons
    @IBOutlet var btnSynopsis: UIButton!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnBackward: UIButton!
    @IBOutlet var btnForward: UIButton!
    
    // Labels
    @IBOutlet var lblBroadcast: UILabel!
    @IBOutlet var lblDescription: ExpandableLabel!
    @IBOutlet var lblDate: UILabel!
    @IBOutlet var lblElapsedTime: UILabel!
    @IBOutlet var lblDuration: UILabel!
    
    // ImageViews
    @IBOutlet var ivProgressCircle: UIImageView!
    
    // Slider
    @IBOutlet var playSlider: PlaySlider!
    
    // Constraints
    @IBOutlet var constOfLblBroadcastTop: NSLayoutConstraint!
    @IBOutlet var constOfLblDescriptionHeight: NSLayoutConstraint!
    @IBOutlet var constOfLblDateTop: NSLayoutConstraint!
    @IBOutlet var constOfLblDateBottom: NSLayoutConstraint!
    
    var postDescription: String = ""
    var postType: String = ""
    
    // Expand/Collpase
    var isExpanded:Bool = false {
        didSet {
            if !isExpanded {
                self.clipsToBounds = true
                
                self.lblDescription.numberOfLines = 1
                self.lblDescription.shouldExpand = true
                self.lblDescription.text = self.postDescription
                self.lblDescription.collapsed = true
                
                self.constOfLblDateBottom.constant = 20
                self.constOfLblDescriptionHeight.constant = self.postType != Constants.PostTypeDiagnosis ? 18 : 0
                self.btnPlay.isHidden = true
                self.btnBackward.isHidden = true
                self.btnForward.isHidden = true
                self.lblElapsedTime.isHidden = true
                self.lblDuration.isHidden = true
                self.playSlider.isHidden = true
                
            } else {
                self.clipsToBounds = false
                
                if self.postType == Constants.PostTypeDiagnosis {
                    self.constOfLblDescriptionHeight.constant = 0
                    
                } else {
                    let constRect = CGSize(width: self.lblDescription.bounds.size.width, height: .greatestFiniteMagnitude)
                    let boundBox = self.postDescription.boundingRect(with: constRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self.lblDescription.font], context: nil)
                    self.constOfLblDescriptionHeight.constant = ceil(boundBox.height)
                    self.lblDescription.shouldCollapse = true
                    self.lblDescription.text = self.postDescription
                    self.lblDescription.collapsed = false
                }
                
                self.constOfLblDateBottom.constant = 55 + 20
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                    self.lblDescription.numberOfLines = 0
                    
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
        self.postDescription = post.descriptions
        self.postType = post.postType
        
        // Set Broadcast Label
        self.lblBroadcast.text = post.title
        
        self.constOfLblBroadcastTop.constant = self.postType != Constants.PostTypeDiagnosis ? 20 : 14
        self.constOfLblDateTop.constant = self.postType != Constants.PostTypeDiagnosis ? 6 : 0
        
        if post.postType == Constants.PostTypeDiagnosis {
            self.lblDate.text = post.getFormattedDateOnly()
            self.btnSynopsis.isHidden = true
            self.ivProgressCircle.isHidden = true
            
        } else {
            self.lblDate.text = post.getFormattedDate()
            self.btnSynopsis.isHidden = false
            
            if post.orderNumber == "" {
                self.btnSynopsis.setImage(UIImage.init(named: "icon_transcription_inactive"), for: .normal)
                self.ivProgressCircle.isHidden = true
                
            } else {
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
    
}
