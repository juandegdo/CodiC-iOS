//
//  ProfileListCell.swift
//  MedicConnect
//
//  Created by alessandro on 11/27/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import Sheriff

class ProfileListCell: UITableViewCell {
    
    // Buttons
    @IBOutlet var btnPlay: SVGPlayButton!
    @IBOutlet var btnAction: UIButton!
    @IBOutlet var btnLike: TVButton!
    @IBOutlet var btnLoop: UIButton!
    @IBOutlet var btnMessage: UIButton!
    
    // Constraints
    @IBOutlet var constOfLblDescriptionHeight: NSLayoutConstraint!
    @IBOutlet var constOfBtnButtonBottom: NSLayoutConstraint!
    @IBOutlet var constOfTxtVHashtagsHeight: NSLayoutConstraint!
    
    // Labels
    @IBOutlet var lblBroadcast: UILabel!
    @IBOutlet var lblDescription: ExpandableLabel!
    @IBOutlet var lblDate: UILabel!
    @IBOutlet var lblLikedDescription: UILabel!
    
    // BadgeViews
    @IBOutlet var likeBadgeView: GIBadgeView!
    @IBOutlet var commentBadgeView: GIBadgeView!
    
    // TextView
    @IBOutlet weak var txtVHashtags: UITextView!
    
    let likeBadgeViewFont = UIFont(name: "Avenir-Book", size: 12.0) as UIFont? ?? UIFont.systemFont(ofSize: 8.0)
    let commentBadgeViewFont = UIFont(name: "Avenir-Book", size: 12.0) as UIFont? ?? UIFont.systemFont(ofSize: 8.0)

    // Expand/Collpase
    var isExpanded:Bool = false {
        didSet {
            if !isExpanded {
                self.constOfBtnButtonBottom.constant = 14
                self.lblLikedDescription.isHidden = true
                self.txtVHashtags.isHidden = true
                
            } else {
                let constraintRect = CGSize(width: self.txtVHashtags.bounds.size.width, height: .greatestFiniteMagnitude)
                let boundingBox = self.txtVHashtags.text == "" ? CGRect.zero : self.txtVHashtags.text?.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: self.txtVHashtags.font!], context: nil)
                
                self.constOfTxtVHashtagsHeight.constant = (boundingBox?.height)! + 16.0
                self.constOfBtnButtonBottom.constant = self.constOfTxtVHashtagsHeight.constant + 20 // 90
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                    self.lblLikedDescription.isHidden = false
                    self.txtVHashtags.isHidden = false
                }
            }
        }
    }
    
    // Descriptioin Expand/Collpase
    var showFullDescription:Bool = false {
        didSet {
            if !showFullDescription {
                self.constOfLblDescriptionHeight.constant = 18
                
            } else {
                let constraintRect = CGSize(width: self.lblDescription.bounds.size.width, height: .greatestFiniteMagnitude)
                let boundingBox = self.lblDescription.text?.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: self.lblDescription.font], context: nil)
                
                self.constOfLblDescriptionHeight.constant = (boundingBox?.height)! + 4.0
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.btnPlay.playColor = UIColor.black
        self.btnPlay.pauseColor = UIColor.black
        self.btnPlay.progressTrackColor = Constants.ColorLightGray
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.lblDescription.collapsed = true
        self.lblDescription.text = nil
        
        if self.likeBadgeView != nil {
            self.likeBadgeView.removeFromSuperview()
            self.likeBadgeView = nil
        }
        
        if self.commentBadgeView != nil {
            self.commentBadgeView.removeFromSuperview()
            self.commentBadgeView = nil
        }
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        
    }

    func setData(post: Post) {
        
        // Set Broadcast Label
        self.lblBroadcast.text = post.title
//        self.lblDescription.text = post.description
        self.lblDate.text = post.getFormattedDate().uppercased()
        
        // Set like description label
        if let likeDescription = post.likeDescription as String?, !likeDescription.isEmpty {
            let blackFont: UIFont = UIFont(name: "Avenir-Black", size: 11.0) as UIFont? ?? UIFont.systemFont(ofSize: 11.0)
            let bookFont: UIFont = UIFont(name: "Avenir-Book", size: 11.0) as UIFont? ?? UIFont.systemFont(ofSize: 11.0)
            
            let nsText = likeDescription as NSString
            let textRange = NSMakeRange(0, nsText.length)
            let attributedString = NSMutableAttributedString(string: likeDescription, attributes: [NSFontAttributeName : blackFont])
            
            nsText.enumerateSubstrings(in: textRange, options: .byWords, using: {
                (substring, substringRange, _, _) in
                if (substring == "Liked" || substring == "by" || substring == "and") {
                    attributedString.addAttribute(NSFontAttributeName, value: bookFont, range: substringRange)
                }
            })
            
            self.lblLikedDescription.attributedText = attributedString
            
        } else {
            self.lblLikedDescription.text = "Liked by 0 users"
        }
        
        // Set hashtags textview
        self.txtVHashtags.text = post.hashtags.count > 0 ? post.hashtags.joined(separator: " ") : ""
                
        // Customize badge
        
        if self.likeBadgeView == nil {
            self.likeBadgeView = GIBadgeView()
            //self.likeBadgeView.setMinimumSize(10.0)
            self.likeBadgeView.font = likeBadgeViewFont
            self.likeBadgeView.textColor = Constants.ColorDarkGray2
            self.likeBadgeView.backgroundColor = UIColor.white
            self.likeBadgeView.topOffset = 26.0
            self.likeBadgeView.rightOffset = 11.0
            self.btnLike.addSubview(self.likeBadgeView)
            
            let tapGestureOnLikeBadge = UITapGestureRecognizer(target: self, action: #selector(LikeBadgeTapped))
            likeBadgeView.addGestureRecognizer(tapGestureOnLikeBadge)
        }
        
        self.likeBadgeView.badgeValue = post.likes.count
        
        if self.commentBadgeView == nil {
            self.commentBadgeView = GIBadgeView()
            //commentBadgeView(10.0)
            self.commentBadgeView.font = commentBadgeViewFont
            self.commentBadgeView.textColor = Constants.ColorDarkGray2
            self.commentBadgeView.backgroundColor = UIColor.white
            self.commentBadgeView.topOffset = 26.0
            self.commentBadgeView.rightOffset = 11.0
            self.btnMessage.addSubview(self.commentBadgeView)
            
            let tapGestureOnCommentBadge = UITapGestureRecognizer(target: self, action: #selector(CommentsBadgeTapped))
            commentBadgeView.addGestureRecognizer(tapGestureOnCommentBadge)
        }
        
        self.commentBadgeView.badgeValue = post.commentsCount
        
    }
    
    @IBAction func onLike(sender: AnyObject) {
        
        if self.likeBadgeView.badgeValue == 5 {
            self.likeBadgeView.badgeValue = 10
        } else if (self.likeBadgeView.badgeValue == 15) {
            self.likeBadgeView.badgeValue = 100
        } else if (self.likeBadgeView.badgeValue == 105) {
            self.likeBadgeView.badgeValue = 1000
        } else if (self.likeBadgeView.badgeValue == 1005) {
            self.likeBadgeView.badgeValue = 10000
        } else {
            self.likeBadgeView.increment()
        }
        
    }
    

}

extension ProfileListCell {
    func LikeBadgeTapped() {
        btnLike.sendActions(for: .touchUpInside)
    }
    
    func CommentsBadgeTapped() {
        btnMessage.sendActions(for: .touchUpInside)
    }
}

