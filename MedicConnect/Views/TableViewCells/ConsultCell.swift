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

class ConsultCell: UITableViewCell {
    
    // ImageViews
    @IBOutlet var imgUserAvatar: UIImageView!
    @IBOutlet var ivProgressCircle: UIImageView!
    
    // Buttons
    @IBOutlet var btnSynopsis: UIButton!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnBackward: UIButton!
    @IBOutlet var btnForward: UIButton!
    @IBOutlet var btnSpeaker: UIButton!
    
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
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.txtVHashtags.alpha = 0
                    self.btnSpeaker.alpha = 0
                    self.btnPlay.alpha = 0
                    self.btnBackward.alpha = 0
                    self.btnForward.alpha = 0
                    self.lblElapsedTime.alpha = 0
                    self.lblDuration.alpha = 0
                    self.playSlider.alpha = 0
                })
                
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
                
                self.btnSpeaker.setImage(UIImage(named: AudioHelper.overrideMode == .speaker ? "icon_speaker_on" : "icon_speaker_off"), for: .normal)
                
                UIView.animate(withDuration: 0.7, animations: {
                    self.txtVHashtags.alpha = 1
                    self.btnSpeaker.alpha = 1
                    self.btnPlay.alpha = 1
                    self.btnBackward.alpha = 1
                    self.btnForward.alpha = 1
                    self.lblElapsedTime.alpha = 1
                    self.lblDuration.alpha = 1
                    self.playSlider.alpha = 1
                })
                
//                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                    self.lblDescription.numberOfLines = 0
//                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Hide bottom controls
        self.txtVHashtags.alpha = 0
        self.btnSpeaker.alpha = 0
        self.btnPlay.alpha = 0
        self.btnBackward.alpha = 0
        self.btnForward.alpha = 0
        self.lblElapsedTime.alpha = 0
        self.lblDuration.alpha = 0
        self.playSlider.alpha = 0
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
        } else {
            self.imgUserAvatar.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                         text: post.user.getInitials(),
                                                                                         font: UIFont(name: "Avenir-Book", size: 14)!,
                                                                                         size: CGSize(width: 30, height: 30))
        }
        
    }
    
}
