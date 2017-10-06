//
//  PlaylistItemCell.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-07-18.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import AlamofireImage
import Sheriff

class PlaylistItemCell: UITableViewCell {

    // Buttons
    @IBOutlet var btnPlay: SVGPlayButton!
    @IBOutlet var btnAction: TVButton!
    @IBOutlet var btnLike: TVButton!
    @IBOutlet var btnShare: UIButton!
    @IBOutlet var btnMessage: UIButton!
    @IBOutlet var btnPlaylist: TVButton!
    
    // Labels
    @IBOutlet var lblBroadcast: UILabel!
    @IBOutlet var lblDate: UILabel!
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblDescription: ExpandableLabel!
    @IBOutlet var lblPlaynumbers: UILabel!
    @IBOutlet var lblLikedDescription: UILabel!
    
    // ImageViews
    @IBOutlet var imgUserAvatar: UIImageView!
    
    // BadgeViews
    @IBOutlet var likeBadgeView: GIBadgeView!
    @IBOutlet var commentBadgeView: GIBadgeView!
    
    // TextView
    @IBOutlet weak var txtVHashtags: UITextView!
    
    // Constraints
    @IBOutlet var constOfLblDescriptionHeight: NSLayoutConstraint!
    @IBOutlet var constOfBtnPlaylistBottom: NSLayoutConstraint!
    @IBOutlet var constOfTxtVHashtagsHeight: NSLayoutConstraint!
    
    var placeholderImage: UIImage?
    
    // Fonts
    let likeBadgeViewFont = UIFont(name: "Avenir-Book", size: 12.0) as UIFont? ?? UIFont.systemFont(ofSize: 8.0)
    let commentBadgeViewFont = UIFont(name: "Avenir-Book", size: 12.0) as UIFont? ?? UIFont.systemFont(ofSize: 8.0)
    let placeholderImageFont = UIFont(name: "Avenir-Heavy", size: 25.0) as UIFont? ?? UIFont.systemFont(ofSize: 25.0)
    
    // Expand/Collpase
    var isExpanded:Bool = false {
        didSet {
            if !isExpanded {
                self.constOfBtnPlaylistBottom.constant = 10
                self.lblLikedDescription.isHidden = true
                self.txtVHashtags.isHidden = true
                
            } else {
                let constraintRect = CGSize(width: self.txtVHashtags.bounds.size.width, height: .greatestFiniteMagnitude)
                let boundingBox = self.txtVHashtags.text == "" ? CGRect.zero : self.txtVHashtags.text?.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: self.txtVHashtags.font!], context: nil)
                
                self.constOfTxtVHashtagsHeight.constant = (boundingBox?.height)! + 16.0
                self.constOfBtnPlaylistBottom.constant = self.constOfTxtVHashtagsHeight.constant + 20 // 90
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
        
        self.btnPlay.playColor = Constants.ColorRed
        self.btnPlay.pauseColor = Constants.ColorRed
        self.btnPlay.progressTrackColor = Constants.ColorLightGray
        
        let image = UIImage(named: "tab_icon_playlist")?.withRenderingMode(.alwaysTemplate)
        self.btnPlaylist.setImage(image, for: .normal)
        self.btnPlaylist.tintColor = UIColor(red: 67/255, green: 73/255, blue: 83/255, alpha: 1.0)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.placeholderImage = nil
        
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
        
        // Set core data
        self.lblUsername.text = post.user.fullName
//        self.lblDescription.text = post.description
        
        // Set Broadcast Label
        self.lblBroadcast.text = post.title
        
        // Set Play numbers Label
        let helperString = post.playCount == 1 ? "Play" : "Plays"
        self.lblPlaynumbers.text = "\(post.playCount) \(helperString)"
        
        // Set date label
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
        
        // Customize Avatar
        
        //        if self.placeholderImage == nil {
        //
        //            self.placeholderImage = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: Constants.ColorOrange, text: post.user.getInitials(), font: placeholderImageFont, size: CGSize(width: 86, height: 86))
        //        }
        self.imgUserAvatar.image = nil
        if let imgURL = URL(string: post.user.photo) as URL? {
            self.imgUserAvatar.af_setImage(withURL: imgURL)
            //            self.imgUserAvatar.af_setImage(withURL: imgURL, placeholderImage: self.placeholderImage)
        } else {
            self.imgUserAvatar.image = nil
            //            self.imgUserAvatar.image = self.placeholderImage
        }
    }
}

extension PlaylistItemCell {
    func LikeBadgeTapped() {
        btnLike.sendActions(for: .touchUpInside)
    }
    
    func CommentsBadgeTapped() {
        btnMessage.sendActions(for: .touchUpInside)
    }
}
