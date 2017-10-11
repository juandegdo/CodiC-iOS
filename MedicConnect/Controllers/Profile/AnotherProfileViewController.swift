//
//  AnotherProfileViewController.swift
//  MedicConnect
//
//  Created by alessandro on 11/27/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import AVFoundation
import AlamofireImage
import MessageUI

class AnotherProfileViewController: BaseViewController, ExpandableLabelDelegate {
    
    let ProfileListCellID = "ProfileListCell"
    let PrivateUserTableViewCellID = "PrivateUserTableViewCell"
    
    // Header
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerLabel: UILabel!
    
    // Profile info
    @IBOutlet var viewProfileInfo: UIView!
    @IBOutlet var imgAvatar: UIImageView!
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblDescription: UILabel!
    @IBOutlet var lblFollowerNumber: UILabel!
    @IBOutlet var lblFollowingNumber: UILabel!
    @IBOutlet var btnFollow: UIButton!
    
    // Scroll
    @IBOutlet var mainScrollView: UIScrollView!
    @IBOutlet var tableView: UITableView!
    
    // Constraints
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var headerViewHeightConstraint: NSLayoutConstraint!
    
    var isMyProfile: Bool = false
    var currentUser: User?
    var vcDisappearType : ViewControllerDisappearType = .other
    var OffsetHeaderStop: CGFloat = 321.0
    var selectedDotsIndex = 0
    
    var profileType = 0 //0: normal, 1: private, 2: blocked
    var expandedRows = Set<String>()
    var states = Set<String>()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        OffsetHeaderStop = self.isMyProfile ? 271.0 : 321.0
        self.headerViewHeightConstraint.constant = self.isMyProfile ? 335.0 : 385.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Table Views
        self.tableView.register(UINib(nibName: ProfileListCellID, bundle: nil), forCellReuseIdentifier: ProfileListCellID)
        self.tableView.register(UINib(nibName: PrivateUserTableViewCellID, bundle: nil), forCellReuseIdentifier: PrivateUserTableViewCellID)
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1 ))
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.initViews()
        
        vcDisappearType = .other
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive , object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let tabvc = self.tabBarController as UITabBarController? {
            DataManager.Instance.setLastTabIndex(tabIndex: tabvc.selectedIndex)
        }
        
        if (vcDisappearType == .other) {
            self.releasePlayer()
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        }
        
    }
    
    // MARK: Private methods
    
    func initViews() {
        
        self.tableViewHeightConstraint.constant = self.view.frame.height - self.headerViewHeightConstraint.constant
        
        self.imgAvatar.layer.borderWidth = 1.5
        self.imgAvatar.layer.borderColor = UIColor.white.cgColor
        
        self.btnFollow.isHidden = self.isMyProfile
        
        self.refreshData()
        
    }
    
    func refreshData() {
        
        if let _currentUser = self.currentUser as User? {
            
            // Update UI with basic user info
            self.updateUI(user: _currentUser)
            
            // Fetch all user data (primarily we only had basic info)
            UserService.Instance.getUser(forId: _currentUser.id, completion: {
                (user: User?) in
                
                if let _updatedUser = user as User? {
                    
                    if _updatedUser.isprivate == true {
                        self.profileType = 1
                        for tuser in _updatedUser.follower {
                            if let user = tuser as? User, user.id == UserController.Instance.getUser().id {
                                self.profileType = 0
                            }
                            
                        }
                    }
                    
                    self.currentUser = _updatedUser
                    self.updateUI(user: self.currentUser!)
                } else {
                    self.profileType = 2
                }
                
            })
        }
        
    }
    
    func releasePlayer(onlyState: Bool = false) {
        
        PlayerController.Instance.invalidateTimer()
        
        // Reset player state
        if let _lastPlayed = PlayerController.Instance.lastPlayed as SVGPlayButton? {
            _lastPlayed.tickCount = 0
            _lastPlayed.playing = false
            PlayerController.Instance.shouldSeek = true
            
            if let _player = PlayerController.Instance.player as AVPlayer?,
                let _index = _lastPlayed.index as Int? {
                
                if let _user = self.currentUser {
                    
                    let post = _user.getPosts()[_index]
                    post.setPlayed(time: _player.currentItem!.currentTime(), progress: _lastPlayed.progressStrokeEnd, setLastPlayed: false)
                    
                }
                
            }
            
        }
        
        if let _observer = PlayerController.Instance.playerObserver as Any? {
            PlayerController.Instance.player?.removeTimeObserver(_observer)
        }
        
        if onlyState {
            return
        }
        
        // Pause and reset components
        PlayerController.Instance.player?.pause()
        PlayerController.Instance.player = nil
        PlayerController.Instance.lastPlayed = nil
        
        if let _user = self.currentUser,
            let _index = PlayerController.Instance.currentIndex as Int? {
            let post = _user.getPosts()[_index]
            post.resetCurrentTime()
        }
        
        PlayerController.Instance.currentIndex = nil        
    }
    
    func updateUI(user: User) {
        
        // Customize Avatar
        _ = UIFont(name: "Avenir-Heavy", size: 18.0) as UIFont? ?? UIFont.systemFont(ofSize: 18.0)
        
        if let imgURL = URL(string: user.photo) as URL? {
            self.imgAvatar.af_setImage(withURL: imgURL)
        }
        
        // Customize User name
        self.lblUsername.text = user.fullName
        
        // Customize Description
        self.lblDescription.text  = user.description
        
        // Customize Following/Follower
        self.lblFollowerNumber.text  = "\(user.follower.count)"
        self.lblFollowingNumber.text  = "\(user.following.count)"
        
        if let _me = UserController.Instance.getUser() as User? {
            if (_me.requesting as! [User]).contains(where: { $0.id == user.id }) {
                self.btnFollow.setTitle(NSLocalizedString("REQUESTED", comment: "comment"), for: .normal)
                self.btnFollow.tag = 2
            }else if (_me.following as! [User]).contains(where: { $0.id == user.id }) {
                self.btnFollow.setTitle(NSLocalizedString("FOLLOWING", comment: "comment"), for: .normal)
                self.btnFollow.tag = 1
            } else {
                self.btnFollow.setTitle(NSLocalizedString("FOLLOW", comment: "comment"), for: .normal)
                self.btnFollow.tag = 0
            }
            
            self.btnFollow.makeEnabled(enabled: true)
        }
        
        if self.profileType == 0 {
            // Private
            self.tableView.estimatedRowHeight = 110.0
            self.tableView.rowHeight = UITableViewAutomaticDimension
        } else {
            // Non Private
            self.tableView.rowHeight = 150.0
        }
        
        self.tableView.reloadData()
        self.updateScroll(offset: self.mainScrollView.contentOffset.y)
        
    }
    
    func loadMe() {
        
        UserService.Instance.getMe(completion: {
            (user: User?) in
            
            self.dismissVC()
        })
        
    }
    
    func updateScroll(offset: CGFloat) {
        
        self.viewProfileInfo.alpha = max (0.0, (OffsetHeaderStop - offset) / OffsetHeaderStop)
        
        // ScrollViews Frame
        if (offset >= OffsetHeaderStop) {
            self.tableViewTopConstraint.constant = offset - OffsetHeaderStop + self.headerViewHeightConstraint.constant - 60.0
            self.tableViewHeightConstraint.constant = self.view.frame.height - (self.headerViewHeightConstraint.constant - OffsetHeaderStop)
            self.getCurrentScroll().setContentOffset(CGPoint(x: 0, y: offset - OffsetHeaderStop), animated: false)
        }
        else {
            self.tableViewTopConstraint.constant = self.headerViewHeightConstraint.constant - 60.0
            self.tableViewHeightConstraint.constant = self.view.frame.height - self.headerViewHeightConstraint.constant + offset
            self.getCurrentScroll().setContentOffset(CGPoint.zero, animated: false)
        }
        
    }
    
    func getCurrentScroll() -> UIScrollView {
        
        let scrollView: UIScrollView = self.tableView
        self.mainScrollView.contentSize = CGSize(width: self.view.frame.width, height: max(self.view.frame.height + OffsetHeaderStop, scrollView.contentSize.height + self.headerViewHeightConstraint.constant))
        return scrollView
        
    }
    
    func callEditVC() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController {
            self.present(vc, animated: false, completion: nil)
        }
        
    }
    
    func callSearchResultVC(hashtag: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "SearchResultsViewController") as? SearchResultsViewController {
            vc.hashtag = "#\(hashtag)"
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    // MARK: Selectors
    
    func onToggleLike(sender: TVButton) {
        
        guard let _index = sender.index as Int? else {
            return
        }
        
        guard let _user = self.currentUser else {
            return
        }
        
        let post = _user.getPosts()[_index]
        
        sender.makeEnabled(enabled: false)
        if sender.tag == 1 {
            PostService.Instance.unlike(postId: post.id, completion: { (success, like_description) in
                sender.makeEnabled(enabled: true)
                
                if success, let like_description = like_description {
                    print("Post succesfully unliked")
                    
                    post.removeLike(id: UserController.Instance.getUser().id)
                    post.likeDescription = like_description
                    if let cell = self.tableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? ProfileListCell {
                        cell.setData(post: post)
                        
                        cell.btnLike.setImage(UIImage(named: "icon_broadcast_like"), for: .normal)
                        cell.btnLike.tag = 0
                    }
                }
            })
            
        } else {
            PostService.Instance.like(postId: post.id, completion: { (success, like_description) in
                sender.makeEnabled(enabled: true)
                
                if success, let like_description = like_description {
                    print("Post succesfully liked")
                    
                    post.addLike(id: UserController.Instance.getUser().id)
                    post.likeDescription = like_description
                    if let cell = self.tableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? ProfileListCell {
                        cell.setData(post: post)
                        
                        cell.btnLike.setImage(UIImage(named: "icon_broadcast_liked"), for: .normal)
                        cell.btnLike.tag = 1
                    }
                }
            })
            
        }
        
    }
    
    func onToggleAction(sender: UIButton) {
        
        print("\(sender.tag)")
        selectedDotsIndex = sender.tag
        if let _user = self.currentUser {
            let post = _user.getPosts()[sender.tag]
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            
            let actionReportThisBroadcast = UIAlertAction(title: "Report this broadcast", style: .destructive) { (action) in
                
                guard let _user = UserController.Instance.getUser() as User? else {
                    return
                }
                
                UserService.Instance.report(from: _user.email, subject: "Report this broadcast", msgbody: "User: \(post.user.fullName)\nUrl: \(post.audio)", completion: { (success) in
                    
                    if success {
                        DispatchQueue.main.async {
                            AlertUtil.showOKAlert(self, message: "Thanks for reporting this broadcast.\nWe are looking into it.")
                        }
                    }
                    
                });
                
            }
            let actionReportUser = UIAlertAction(title: "Report this user", style: .destructive) { (action) in
                
                guard let _user = UserController.Instance.getUser() as User? else {
                    return
                }
                
                UserService.Instance.report(from: _user.email, subject: "Report this user", msgbody: "User: \(post.user.fullName)", completion: { (success) in
                    
                    if success {
                        DispatchQueue.main.async {
                            AlertUtil.showOKAlert(self, message: "Thanks for reporting this broadcaster.\nWe are looking into it.")
                        }
                    }
                    
                });
                
            }
            let actionBlockUser = UIAlertAction(title: "Block user", style: .default) { (action) in
                UserService.Instance.block(userId: _user.id , completion: {
                    (success: Bool) in
                    
                    if success {
                        DispatchQueue.main.async {
                            AlertUtil.showOKAlert(self, message: "This user is now blocked.\nGo to Settings to undo this action.")
                        }
                        
                        self.loadMe()
                    } else {
                        sender.makeEnabled(enabled: true)
                    }
                    
                })
            }
            let actionTurnOnPost = UIAlertAction(title: "Turn on Post notification", style: .default) { (action) in
                
            }
            let actionCopyShareUrl = UIAlertAction(title: "Copy Share Url", style: .default) { (action) in
                UIPasteboard.general.string = post.audio
            }
            
            let actionCancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
            
            alertController.addAction(actionReportThisBroadcast)
            alertController.addAction(actionReportUser)
            alertController.addAction(actionBlockUser)
            alertController.addAction(actionTurnOnPost)
            alertController.addAction(actionCopyShareUrl)
            alertController.addAction(actionCancel)
            
            alertController.view.tintColor = UIColor.black
            
            present(alertController, animated: false, completion: nil)
        }
    }
    
    func onSelectShare(sender: UIButton) {
        
        vcDisappearType = .share
        
        self.performSegue(withIdentifier: Constants.SegueMedicConnectShareBroadcastPopup, sender: nil)
        
    }
    
    func onSelectComment(sender: UIButton) {
        
        vcDisappearType = .comment
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            if let _user = self.currentUser {
                let post = _user.getPosts()[sender.tag]
                vc.currentPost = post
                
                self.present(vc, animated: false, completion: nil)
            }
        }
        
    }
    
    func onSelectLikeDescription(sender: UITapGestureRecognizer) {
        
        vcDisappearType = .like
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "LikesViewController") as? LikesViewController {
            if let _user = self.currentUser,
                let index = sender.view?.tag {
                let post = _user.getPosts()[index]
                vc.currentPost = post
                
                self.present(vc, animated: false, completion: nil)
            }
        }
        
    }
    
    func onSelectHashtag (sender: UITapGestureRecognizer) {
        let myTextView = sender.view as! UITextView //sender is TextView
        let _pos: CGPoint = sender.location(in: myTextView)
        
        //eliminate scroll offset
        //        pos.y += _tv.contentOffset.y;
        
        //get location in text from textposition at point
        let tapPos = myTextView.closestPosition(to: _pos)
        
        //fetch the word at this position (or nil, if not available)
        if let wordRange = myTextView.tokenizer.rangeEnclosingPosition(tapPos!, with: UITextGranularity.word, inDirection: UITextLayoutDirection.right.rawValue),
            let tappedHashtag = myTextView.text(in: wordRange) {
            NSLog("Word: \(String(describing: tappedHashtag))")
            self.callSearchResultVC(hashtag: tappedHashtag)
        }
        
    }
    
    func onPlayAudio(sender: SVGPlayButton) {
        
        guard let _index = sender.index as Int? else {
            return
        }
        
        guard let _user = self.currentUser else {
            return
        }
        
        let post = _user.getPosts()[_index]
        
        self.releasePlayer(onlyState: true)
        
        if let _url = URL(string: post.audio ) as URL? {
            if let _player = PlayerController.Instance.player as AVPlayer?,
                let _currentIndex = PlayerController.Instance.currentIndex as Int?, _currentIndex == _index {
                
                PlayerController.Instance.lastPlayed = sender
                
                PlayerController.Instance.shouldSeek = false
                _player.rate = 1.0
                PlayerController.Instance.currentTime = post.getCurrentTime()
                _player.play()
                
                PlayerController.Instance.addObserver()
                
            } else {
                
                let playerItem = AVPlayerItem(url: _url)
                PlayerController.Instance.player = AVPlayer(playerItem:playerItem)
                
                if let _player = PlayerController.Instance.player as AVPlayer? {
                    
                    AudioHelper.SetCategory(mode: AVAudioSessionPortOverride.speaker)
                    
                    PlayerController.Instance.lastPlayed = sender
                    PlayerController.Instance.currentIndex = _index
                    
                    _player.rate = 1.0
                    PlayerController.Instance.currentTime = post.getCurrentTime()
                    _player.play()
                    
                    PlayerController.Instance.addObserver()
                    
                    if Float(_player.currentTime().value) == 0.0 {
                        PostService.Instance.incrementPost(id: post.id, completion: { (success, play_count) in
                            if success, let play_count = play_count {
                                print("Post incremented")
                                post.playCount = play_count
                                if let cell = self.tableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? ProfileListCell {
                                    cell.setData(post: post)
                                }
                            }
                        })
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func willEnterBackground() {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        _player.pause()
        
        if let sender = PlayerController.Instance.lastPlayed {
            sender.playing = false
            guard let _index = sender.index as Int? else {
                return
            }
            
            guard let _user = self.currentUser else {
                return
            }
            
            let post = _user.getPosts()[_index]
            post.setPlayed(time: _player.currentItem!.currentTime(), progress: sender.progressStrokeEnd)
        }
        
        PlayerController.Instance.lastPlayed?.tickCount = 0
        PlayerController.Instance.lastPlayed = nil
        PlayerController.Instance.shouldSeek = true
        
        PlayerController.Instance.scheduleReset()
    }
    
    
    func onPauseAudio(sender: SVGPlayButton) {
        
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        _player.pause()
        PlayerController.Instance.lastPlayed?.tickCount = 0
        PlayerController.Instance.lastPlayed = nil
        PlayerController.Instance.shouldSeek = true
        
        PlayerController.Instance.scheduleReset()
        
        guard let _index = sender.index as Int? else {
            return
        }
        
        guard let _user = self.currentUser else {
            return
        }
        
        let post = _user.getPosts()[_index]
        post.setPlayed(time: _player.currentItem!.currentTime(), progress: sender.progressStrokeEnd)
        
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        
        self.releasePlayer()
        
    }
    
}

extension AnotherProfileViewController : UITableViewDataSource, UITableViewDelegate {
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        
        if (tableView == self.tableView) {
            
            if let _user = self.currentUser {
                if profileType == 0 {
                    return _user.getPosts().count
                } else {
                    return 1
                }
            } else {
                return 0
            }
            
        }
        
        return 0
        
    }
    
    // MARK: UITableView Datasource methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == self.tableView {
            tableView.backgroundView = nil
            return 1
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.numberOfRows(inTableView: tableView, section: section)
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tableView {
            if profileType > 0 {
                let cellPrivate = tableView.dequeueReusableCell(withIdentifier: PrivateUserTableViewCellID, for: indexPath)
                return cellPrivate
            }
            
            let cell: ProfileListCell = tableView.dequeueReusableCell(withIdentifier: ProfileListCellID, for: indexPath) as! ProfileListCell
            
            guard let _user = self.currentUser else {
                return cell
            }
            
            let post = _user.getPosts()[indexPath.row]
            cell.setData(post: post)
            
            cell.btnLoop.tag = indexPath.row
            cell.btnLoop.addTarget(self, action: #selector(onSelectShare(sender:)), for: .touchUpInside)
            
            cell.btnMessage.tag = indexPath.row
            cell.btnMessage.addTarget(self, action: #selector(onSelectComment(sender:)), for: .touchUpInside)
            
            cell.btnPlay.willPlay = { self.onPlayAudio(sender: cell.btnPlay) }
            cell.btnPlay.willPause = { self.onPauseAudio(sender: cell.btnPlay)  }
            cell.btnPlay.index = indexPath.row
            cell.btnPlay.refTableView = tableView
            cell.btnPlay.progressStrokeEnd = post.getCurrentProgress()
            
            if cell.btnPlay.playing {
                cell.btnPlay.playing = false
            }
            
            cell.btnLike.addTarget(self, action: #selector(onToggleLike(sender:)), for: .touchUpInside)
            cell.btnLike.index = indexPath.row
            cell.btnLike.isEnabled = !isMyProfile
            
            if let _user = UserController.Instance.getUser() {
                let hasLiked = post.hasLiked(id: _user.id)
                let image = hasLiked ? UIImage(named: "icon_broadcast_liked") : UIImage(named: "icon_broadcast_like")
                cell.btnLike.setImage(image, for: .normal)
                cell.btnLike.tag = hasLiked ? 1 : 0
                
                let hasCommented = post.hasCommented(id: _user.id)
                let image1 = hasCommented ? UIImage(named: "icon_broadcast_messaged") : UIImage(named: "icon_broadcast_message")
                cell.btnMessage.setImage(image1, for: .normal)
            }
            
            cell.btnAction.addTarget(self, action: #selector(onToggleAction(sender:)), for: .touchUpInside)
            cell.btnAction.tag = indexPath.row
            
            let isFullDesc = self.states.contains(post.id)
            cell.lblDescription.delegate = self
            cell.lblDescription.shouldCollapse = true
            cell.lblDescription.numberOfLines = isFullDesc ? 0 : 1;
            cell.lblDescription.text = post.description
            cell.lblDescription.collapsed = !isFullDesc
            cell.showFullDescription = isFullDesc
            
            let tapGestureOnLikeDescription = UITapGestureRecognizer(target: self, action: #selector(onSelectLikeDescription(sender:)))
            cell.lblLikedDescription.addGestureRecognizer(tapGestureOnLikeDescription)
            cell.lblLikedDescription.tag = indexPath.row
            
            let tapGestureOnHashtags = UITapGestureRecognizer(target: self, action: #selector(onSelectHashtag(sender:)))
            cell.txtVHashtags.addGestureRecognizer(tapGestureOnHashtags)
            cell.txtVHashtags.tag = indexPath.row
            
            cell.isExpanded = self.expandedRows.contains(post.id)
            cell.selectionStyle = .none
            
            return cell
        } else {
            return UITableViewCell()
        }
        
    }
    
    // MARK: UITableView Delegate methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView {
            guard let cell = tableView.cellForRow(at: indexPath) as? ProfileListCell
                else { return }
            
            guard let _user = self.currentUser else {
                return
            }
            
            let post = _user.getPosts()[indexPath.row]
            
            switch cell.isExpanded {
            case true:
                self.expandedRows.remove(post.id)
                
            case false:
                self.expandedRows.insert(post.id)
            }
            
            cell.isExpanded = !cell.isExpanded
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView {
            guard let cell = tableView.cellForRow(at: indexPath) as? ProfileListCell
                else { return }
            
            guard let _user = self.currentUser else {
                return
            }
            
            let post = _user.getPosts()[indexPath.row]
            self.expandedRows.remove(post.id)
            
            cell.isExpanded = false
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
        
    }
    
    //
    // MARK: ExpandableLabel Delegate
    //
    
    func willExpandLabel(_ label: ExpandableLabel) {
        self.tableView.beginUpdates()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point) as IndexPath? {
            guard let cell = self.tableView.cellForRow(at: indexPath) as? ProfileListCell
                else { return }
            
            guard let _user = self.currentUser else {
                return
            }
            
            let post = _user.getPosts()[indexPath.row]
            self.states.insert(post.id)
            
            cell.showFullDescription = true
        }
        self.tableView.endUpdates()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        self.tableView.beginUpdates()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point) as IndexPath? {
            guard let cell = self.tableView.cellForRow(at: indexPath) as? ProfileListCell
                else { return }
            
            guard let _user = self.currentUser else {
                return
            }
            
            let post = _user.getPosts()[indexPath.row]
            self.states.remove(post.id)
            
            cell.showFullDescription = false
        }
        self.tableView.endUpdates()
    }
    
}

extension AnotherProfileViewController : UIScrollViewDelegate {

    // MARK: UIScrollViewDelegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == self.mainScrollView {
            
            let offset: CGFloat = scrollView.contentOffset.y
            
            var headerTransform: CATransform3D = CATransform3DIdentity
            
            if offset < 0 { // PULL DOWN -----------------
                
                let headerScaleFactor: CGFloat = -(offset) / self.headerView.bounds.height
                let headerSizevariation: CGFloat = ((self.headerView.bounds.height * (1.0 + headerScaleFactor)) - self.headerView.bounds.height) / 2.0
                headerTransform = CATransform3DTranslate(headerTransform, 0, headerSizevariation, 0)
                headerTransform = CATransform3DScale(headerTransform, 1.0 + headerScaleFactor, 1.0 + headerScaleFactor, 0)
                
                // Apply Transformations
                self.headerView.layer.transform = headerTransform
                self.viewProfileInfo.layer.transform = CATransform3DIdentity
            }
            else { // SCROLL UP/DOWN ------------
                
                self.updateScroll(offset: offset)
            }
        }
        
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        
        if scrollView == self.mainScrollView {
            self.tableView.setContentOffset(CGPoint.zero, animated: true)
        }
        
    }
    
}

extension AnotherProfileViewController {
    //MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onMyFollowers(sender: AnyObject!) {
        
//        self.callFollowerVC()
        
    }
    
    @IBAction func onMyFollowings(sender: AnyObject!) {
        
//        self.callFollowingVC()
        
    }
    
    @IBAction func onFollow(sender: AnyObject!) {
        
        guard let _currentUser = self.currentUser as User? else {
            return
        }
        if sender.tag == 2 {
            return
        }
        
        self.btnFollow.makeEnabled(enabled: false)
        if sender.tag == 0 {
            UserService.Instance.follow(userId: _currentUser.id, completion: {
                (success: Bool) in
                
                if success {
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        self.refreshData()
                    })
                } else {
                    self.btnFollow.makeEnabled(enabled: true)
                }
            })
            
        } else {
            
            UserService.Instance.unfollow(userId: _currentUser.id, completion: {
                (success: Bool) in
                
                if success {
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        self.refreshData()
                    })
                } else {
                    self.btnFollow.makeEnabled(enabled: true)
                }
            })
            
        }
        
    }
}
