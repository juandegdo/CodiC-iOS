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
    @IBOutlet var btnSpeaker: UIButton!
    
    // Labels
    @IBOutlet var lblBroadcast: UILabel!
    @IBOutlet var lblDescription: ExpandableLabel!
    @IBOutlet var lblDate: UILabel!
    @IBOutlet var lblElapsedTime: UILabel!
    @IBOutlet var lblDuration: UILabel!
    
    // Container View
    @IBOutlet var viewDoctors: UIView!
    
    // ImageViews
    @IBOutlet var ivProgressCircle: UIImageView!
    
    // Slider
    @IBOutlet var playSlider: PlaySlider!
    
    // Constraints
    @IBOutlet var constOfLblBroadcastTop: NSLayoutConstraint!
    @IBOutlet var constOfLblDescriptionHeight: NSLayoutConstraint!
    @IBOutlet var constOfLblDateTop: NSLayoutConstraint!
    @IBOutlet var constOfLblDateBottom: NSLayoutConstraint!
    @IBOutlet var constOfDocsViewWidth: NSLayoutConstraint!
    @IBOutlet var constOfBtnPlayTop: NSLayoutConstraint!
    
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
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.viewDoctors.alpha = 0
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
                
                self.constOfLblDateBottom.constant = 65 + self.constOfBtnPlayTop.constant
                
                self.btnSpeaker.setImage(UIImage(named: AudioHelper.overrideMode == .speaker ? "icon_speaker_on" : "icon_speaker_off"), for: .normal)
                
                UIView.animate(withDuration: 0.7, animations: {
                    self.viewDoctors.alpha = 1
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
        self.viewDoctors.alpha = 0
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
        
        // Referring Doctor images
        for view in self.viewDoctors.subviews {
            let imgView: UIImageView = view.viewWithTag(200) as! UIImageView
            imgView.layer.borderWidth = 1.0
            imgView.layer.borderColor = UIColor.init(red: 107/255.0, green: 199/255.0, blue: 213/255.0, alpha: 1.0).cgColor
        }
        
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
        self.postDescription = post.descriptions
        self.postType = post.postType
        
        self.constOfLblBroadcastTop.constant = self.postType != Constants.PostTypeDiagnosis ? 20 : 14
        self.constOfLblDateTop.constant = self.postType != Constants.PostTypeDiagnosis ? 6 : 0
        
        if post.postType == Constants.PostTypeDiagnosis {
            // Set Broadcast Label
            self.lblBroadcast.text = post.title
            self.lblDate.text = post.getFormattedDateOnly()
            
            self.btnSynopsis.isHidden = true
            self.ivProgressCircle.isHidden = true
            
        } else {
            // Set Broadcast Label
            self.lblBroadcast.text = "\(post.patientName) \(post.patientPHN)"
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
        // Show referring doctors' images
        self.constOfBtnPlayTop.constant = post.referringUsers.count == 0 ? 10 : 32
        
        for index in 0...2 {
            if let view = self.viewDoctors.viewWithTag(index + 100) {
                if index < post.referringUsers.count {
                    view.isHidden = false
                    
                    if let imgView = view.viewWithTag(200) as? UIImageView {
                        let user = post.referringUsers[index]
                        if let imgURL = URL(string: user.photo) as URL? {
                            imgView.af_setImage(withURL: imgURL)
                        } else {
                            imgView.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                                     text: user.getInitials(),
                                                                                                     font: UIFont(name: "Avenir-Book", size: 13)!,
                                                                                                     size: CGSize(width: 28, height: 28))
                        }
                    }
                    
                } else {
                    view.isHidden = true
                }
            }
        }
        
    }
    
}
