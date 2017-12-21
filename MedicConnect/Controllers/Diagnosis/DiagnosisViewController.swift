//
//  DiagnosisViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-11.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import AVFoundation
import Crashlytics

public enum ViewControllerDisappearType {
    case comment
    case like
    case share
    case other
    case record
}

class DiagnosisViewController: BaseViewController, UIGestureRecognizerDelegate, ExpandableLabelDelegate {
    
    let DiagnosisCellID = "PlaylistCell"
    let postType = Constants.PostTypeDiagnosis
    
    @IBOutlet var tvDiagnoses: UITableView!
    
    var vcDisappearType : ViewControllerDisappearType = .other
    var selectedDotsIndex = 0
    var expandedRows = Set<String>()
    var states = Set<String>()
    var selectedRowIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initViews()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadMe()
        
        vcDisappearType = .other
        NotificationCenter.default.addObserver(self, selector: #selector(DiagnosisViewController.playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        
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
    
    // MARK: Private Functions
    
    func initViews() {
        
        // Initialize Table Views
        
        let nibDiagnosisCell = UINib(nibName: DiagnosisCellID, bundle: nil)
        self.tvDiagnoses.register(nibDiagnosisCell, forCellReuseIdentifier: DiagnosisCellID)
        
        self.tvDiagnoses.tableFooterView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.tvDiagnoses.frame.size.width, height: 20.0))
        self.tvDiagnoses.estimatedRowHeight = 132.0
        self.tvDiagnoses.rowHeight = UITableViewAutomaticDimension
        
    }
    
}

extension DiagnosisViewController {
    
    // MARK: Private methods
    
    func loadPosts() {
        
        // Load Timeline
        UserService.Instance.getTimeline(completion: {
            (success: Bool) in
            if success {
                self.selectedRowIndex = (self.tvDiagnoses.indexPathForSelectedRow != nil) ? self.tvDiagnoses.indexPathForSelectedRow!.row : -1
                self.tvDiagnoses.reloadData()
            }
        })
        
    }
    
    func loadMe() {
        
        UserService.Instance.getMe(completion: {
            (user: User?) in
            
            if let _user = user as User? {
                self.logUser(user: _user)
                self.loadPosts()
            }
        })
        
    }
    
    func releasePlayer(onlyState: Bool = false) {
        
        PlayerController.Instance.invalidateTimer()
        
        // Reset player state
        if let _lastPlayed = PlayerController.Instance.lastPlayed as PlaySlider?,
            let _elapsedLabel = PlayerController.Instance.elapsedTimeLabel as UILabel?,
            let _durationLabel = PlayerController.Instance.durationLabel as UILabel? {
            _lastPlayed.setValue(0.0, animated: false)
            _lastPlayed.playing = false
            _elapsedLabel.text = "0:00"
            _durationLabel.text = "0:00"
        }
        
        if let _observer = PlayerController.Instance.playerObserver as Any? {
            PlayerController.Instance.player?.removeTimeObserver(_observer)
            PlayerController.Instance.playerObserver = nil
            PlayerController.Instance.player?.seek(to: kCMTimeZero)
        }
        
        if let _index = PlayerController.Instance.currentIndex as Int? {
            let post = PostController.Instance.getFollowingPosts(type: self.postType)[_index]
            post.setPlayed(time: kCMTimeZero, progress: 0.0, setLastPlayed: false)
            
            let cell = self.tvDiagnoses.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? PlaylistCell
            cell?.btnPlay.setImage(UIImage.init(named: "icon_playlist_play"), for: .normal)
        }
        
        if onlyState {
            return
        }
        
        // Pause and reset components
        PlayerController.Instance.player?.pause()
        PlayerController.Instance.player = nil
        PlayerController.Instance.lastPlayed = nil
        PlayerController.Instance.elapsedTimeLabel = nil
        PlayerController.Instance.durationLabel = nil
        PlayerController.Instance.currentIndex = nil
        
    }
    
    func onPlayAudio(sender: UIButton) {
        
        guard let _index = sender.tag as Int? else {
            return
        }
        
        if let _lastPlayed = PlayerController.Instance.lastPlayed,
            _lastPlayed.playing == true {
            self.onPauseAudio(sender: sender)
            return
        }
        
        let post = PostController.Instance.getFollowingPosts(type: self.postType)[_index]
        
        if let _url = URL(string: post.audio ) as URL? {
            let cell = self.tvDiagnoses.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? PlaylistCell
            sender.setImage(UIImage.init(named: "icon_playlist_pause"), for: .normal)
            
            if let _player = PlayerController.Instance.player as AVPlayer?,
                let _currentIndex = PlayerController.Instance.currentIndex as Int?, _currentIndex == _index {
                
                PlayerController.Instance.lastPlayed = cell?.playSlider
                PlayerController.Instance.elapsedTimeLabel = cell?.lblElapsedTime
                PlayerController.Instance.durationLabel = cell?.lblDuration
                PlayerController.Instance.shouldSeek = false
                
                _player.rate = 1.0
                _player.play()
                
                PlayerController.Instance.addObserver()
                
            } else {
                
                let playerItem = AVPlayerItem(url: _url)
                PlayerController.Instance.player = AVPlayer(playerItem:playerItem)
                
                if let _player = PlayerController.Instance.player as AVPlayer? {
                    
                    AudioHelper.SetCategory(mode: AVAudioSessionPortOverride.speaker)
                    
                    PlayerController.Instance.lastPlayed = cell?.playSlider
                    PlayerController.Instance.elapsedTimeLabel = cell?.lblElapsedTime
                    PlayerController.Instance.durationLabel = cell?.lblDuration
                    PlayerController.Instance.currentIndex = _index
                    PlayerController.Instance.shouldSeek = true
                    PlayerController.Instance.currentTime = post.getCurrentTime()
                    
                    _player.rate = 1.0
                    _player.play()
                    
                    PlayerController.Instance.addObserver()
                    
                    if Float(_player.currentTime().value) == 0.0 {
                        PostService.Instance.incrementPost(id: post.id, completion: { (success, play_count) in
                            if success, let play_count = play_count {
                                print("Post incremented")
                                post.playCount = play_count
                                // cell?.setData(post: post)
                            }
                        })
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func onPauseAudio(sender: UIButton) {
        
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        _player.pause()
        sender.setImage(UIImage.init(named: "icon_playlist_play"), for: .normal)
        
        if let _lastPlayed = PlayerController.Instance.lastPlayed as PlaySlider? {
            if let _observer = PlayerController.Instance.playerObserver as Any? {
                PlayerController.Instance.player?.removeTimeObserver(_observer)
                PlayerController.Instance.playerObserver = nil
            }
            
            _lastPlayed.playing = false
            
            guard let _index = sender.tag as Int? else {
                return
            }
            
            let post = PostController.Instance.getFollowingPosts(type: self.postType)[_index]
            post.setPlayed(time: _player.currentItem!.currentTime(), progress: CGFloat(_lastPlayed.value))
        }
        
    }
    
    func onBackwardAudio(sender: UIButton) {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        if _player.status != .readyToPlay {
            return
        }
        
        var time = CMTimeGetSeconds(_player.currentTime())
        if time == 0 { return }
        time = time - 15 >= 0 ? time - 15 : 0
        
        self.seekToTime(time: time)
    }
    
    func onForwardAudio(sender: UIButton) {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        if _player.status != .readyToPlay {
            return
        }
        
        var time = CMTimeGetSeconds(_player.currentTime())
        let duration = CMTimeGetSeconds((_player.currentItem?.duration)!)
        if time == duration { return }
        time = time + 15 <= duration ? time + 15 : duration
        
        self.seekToTime(time: time)
    }
    
    func onSeekSlider(sender: UISlider) {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        if _player.status != .readyToPlay {
            return
        }
        
        let duration = CMTimeGetSeconds((_player.currentItem?.duration)!)
        let time = duration * Float64(sender.value)
        
        self.seekToTime(time: time)
    }
    
    func seekToTime(time: Float64) {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        _player.seek(to: CMTimeMakeWithSeconds(time, _player.currentTime().timescale), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        
        if let _lastPlayed = PlayerController.Instance.lastPlayed,
            let _elapsedLabel = PlayerController.Instance.elapsedTimeLabel,
            _lastPlayed.playing == false {
            
            _lastPlayed.setValue(Float(time / CMTimeGetSeconds((_player.currentItem?.duration)!)), animated: false)
            _elapsedLabel.text = TimeInterval(time).durationText
            
            guard let _index = _lastPlayed.index as Int? else {
                return
            }
            
            let post = PostController.Instance.getFollowingPosts(type: self.postType)[_index]
            post.setPlayed(time: CMTimeMakeWithSeconds(time, _player.currentTime().timescale), progress: CGFloat(_lastPlayed.value))
            
        }
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        self.releasePlayer(onlyState: true)
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
            
            let post = PostController.Instance.getFollowingPosts(type: self.postType)[_index]
            post.setPlayed(time: _player.currentItem!.currentTime(), progress: CGFloat(sender.value))
        }
        
        PlayerController.Instance.lastPlayed?.setValue(Float(0.0), animated: false)
        PlayerController.Instance.lastPlayed = nil
        PlayerController.Instance.elapsedTimeLabel?.text = "0:00"
        PlayerController.Instance.elapsedTimeLabel = nil
        PlayerController.Instance.durationLabel?.text = "0:00"
        PlayerController.Instance.durationLabel = nil
        PlayerController.Instance.shouldSeek = true
        PlayerController.Instance.scheduleReset()
        
    }
    
    func onToggleAction(sender: TVButton) {
        guard let _ = sender.index as Int?,
            let _ = sender.refTableView as UITableView? else {
                return
        }
        
        print("\(sender.index!)")
        selectedDotsIndex = sender.index!
        let post = PostController.Instance.getFollowingPosts(type: self.postType)[selectedDotsIndex]
        
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
            UserService.Instance.block(userId: post.user.id , completion: {
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
    
    func onToggleLike(sender: TVButton) {
        
        guard let _index = sender.index as Int?,
            let _refTableView = sender.refTableView as UITableView? else {
                return
        }
        
        let post = PostController.Instance.getFollowingPosts(type: self.postType)[_index]
        
        guard let _user = UserController.Instance.getUser() as User? else {
            return
        }
        
        sender.makeEnabled(enabled: false)
        if sender.tag == 1 {
            PostService.Instance.unlike(postId: post.id, completion: { (success, like_description) in
                sender.makeEnabled(enabled: true)
                
                if success, let like_description = like_description {
                    print("Post succesfully unliked")
                    
                    post.removeLike(id: _user.id)
                    post.likeDescription = like_description
                    if let cell = _refTableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? PlaylistCell {
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
                    
                    post.addLike(id: _user.id)
                    post.likeDescription = like_description
                    if let cell = _refTableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? PlaylistCell {
                        cell.setData(post: post)
                        
                        cell.btnLike.setImage(UIImage(named: "icon_broadcast_liked"), for: .normal)
                        cell.btnLike.tag = 1
                    }
                }
            })
            
        }
        
    }
    
    func callProfileVC(user: User) {
        
        if  let _me = UserController.Instance.getUser() as User? {
            if _me.id == user.id {
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if  let vc = storyboard.instantiateViewController(withIdentifier: "AnotherProfileViewController") as? AnotherProfileViewController {
                
                if let blockedby = _me.blockedby as? [User] {
                    if blockedby.contains(where: { $0.id == user.id }) {
                        return
                    }
                }
                if let blocking = _me.blocking as? [User] {
                    if blocking.contains(where: { $0.id == user.id }) {
                        return
                    }
                }
                
                vc.currentUser = user
                self.present(vc, animated: false, completion: nil)
                
            }
        }
        
    }
    
    func callSearchResultVC(hashtag: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "SearchResultsViewController") as? SearchResultsViewController {
            vc.hashtag = hashtag
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    // MARK: Selectors
    
    func onSelectShare(sender: UIButton) {
        
        vcDisappearType = .share
        
        self.performSegue(withIdentifier: Constants.SegueMedicConnectShareBroadcastPopup, sender: nil)
        
    }
    
    func onSelectComment(sender: UIButton) {
        vcDisappearType = .comment
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            let post : Post? = PostController.Instance.getFollowingPosts(type: self.postType)[sender.tag]
            vc.currentPost = post
            
            self.present(vc, animated: false, completion: nil)
        }
        
    }
    
    func onSelectUser(sender: UITapGestureRecognizer) {
        let index = sender.view?.tag
        let post : Post? = PostController.Instance.getFollowingPosts(type: self.postType)[index!]
        
        if (post != nil) {
            self.callProfileVC(user: (post?.user)!)
        }
    }
    
    func onSelectLikeDescription(sender: UITapGestureRecognizer) {
        vcDisappearType = .like
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "LikesViewController") as? LikesViewController {
            let index = sender.view?.tag
            let post : Post? = PostController.Instance.getFollowingPosts(type: self.postType)[index!]
            
            if (post != nil) {
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
    
    func logUser(user : User) {
        // TODO: Use the current user's information
        // You can call any combination of these three methods
        Crashlytics.sharedInstance().setUserEmail(user.email)
        Crashlytics.sharedInstance().setUserIdentifier(user.id)
        Crashlytics.sharedInstance().setUserName(user.fullName)
    }
}

extension DiagnosisViewController : UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableView DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows(inTableView: tableView, section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: PlaylistCell = tableView.dequeueReusableCell(withIdentifier: DiagnosisCellID) as! PlaylistCell
        
        let post = PostController.Instance.getFollowingPosts(type: self.postType)[indexPath.row]
        cell.setData(post: post)
        
//        cell.btnAction.addTarget(self, action: #selector(onToggleAction(sender:)), for: .touchUpInside)
//        cell.btnAction.index = indexPath.row
//        cell.btnAction.refTableView = tableView
        cell.btnAction.isHidden = true
        
        cell.btnLike.addTarget(self, action: #selector(onToggleLike(sender:)), for: .touchUpInside)
        cell.btnLike.index = indexPath.row
        cell.btnLike.refTableView = tableView
        
        cell.btnMessage.tag = indexPath.row
        cell.btnMessage.addTarget(self, action: #selector(onSelectComment(sender:)), for: .touchUpInside)
        
        cell.btnShare.tag = indexPath.row
        cell.btnShare.addTarget(self, action: #selector(onSelectShare(sender:)), for: .touchUpInside)
        
        if let _user = UserController.Instance.getUser() as User? {
            let hasLiked = post.hasLiked(id: _user.id)
            let image = hasLiked ? UIImage(named: "icon_broadcast_liked") : UIImage(named: "icon_broadcast_like")
            cell.btnLike.setImage(image, for: .normal)
            cell.btnLike.tag = hasLiked ? 1 : 0
            
            let hasCommented = post.hasCommented(id: _user.id)
            let image1 = hasCommented ? UIImage(named: "icon_broadcast_messaged") : UIImage(named: "icon_broadcast_message")
            cell.btnMessage.setImage(image1, for: .normal)
        }
        
        let tapGestureOnUserAvatar = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
        cell.imgUserAvatar.addGestureRecognizer(tapGestureOnUserAvatar)
        cell.imgUserAvatar.tag = indexPath.row
        
        let tapGestureOnUsername = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
        cell.lblUsername.addGestureRecognizer(tapGestureOnUsername)
        cell.lblUsername.tag = indexPath.row
        
        let isFullDesc = self.states.contains(post.id)
        cell.lblDescription.delegate = self
        cell.lblDescription.shouldCollapse = true
        cell.lblDescription.numberOfLines = isFullDesc ? 0 : 1;
        cell.lblDescription.text = post.description
        cell.lblDescription.collapsed = !isFullDesc
        cell.showFullDescription = isFullDesc
        
//        let tapGestureOnLikeDescription = UITapGestureRecognizer(target: self, action: #selector(onSelectLikeDescription(sender:)))
//        cell.lblLikedDescription.addGestureRecognizer(tapGestureOnLikeDescription)
//        cell.lblLikedDescription.tag = indexPath.row
        
        let tapGestureOnHashtags = UITapGestureRecognizer(target: self, action: #selector(onSelectHashtag(sender:)))
        cell.txtVHashtags.addGestureRecognizer(tapGestureOnHashtags)
        cell.txtVHashtags.tag = indexPath.row
        
        cell.btnPlay.tag = indexPath.row
        if cell.btnPlay.allTargets.count == 0 {
            cell.btnPlay.addTarget(self, action: #selector(onPlayAudio(sender:)), for: .touchUpInside)
        }
        
        cell.btnBackward.tag = indexPath.row
        if cell.btnBackward.allTargets.count == 0 {
            cell.btnBackward.addTarget(self, action: #selector(onBackwardAudio(sender:)), for: .touchUpInside)
        }
        
        cell.btnForward.tag = indexPath.row
        if cell.btnForward.allTargets.count == 0 {
            cell.btnForward.addTarget(self, action: #selector(onForwardAudio(sender:)), for: .touchUpInside)
        }
        
        cell.playSlider.index = indexPath.row
        cell.playSlider.setValue(Float(post.getCurrentProgress()), animated: false)
        if cell.playSlider.allTargets.count == 0 {
            cell.playSlider.addTarget(self, action: #selector(onSeekSlider(sender:)), for: .valueChanged)
        }
        
        cell.isExpanded = self.expandedRows.contains(post.id)
        cell.selectionStyle = .none
        
        return cell
        
    }
    
    // MARK: UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistCell
            else { return }
        
        self.releasePlayer()
        self.tvDiagnoses.beginUpdates()
        
        let post = PostController.Instance.getFollowingPosts(type: self.postType)[indexPath.row]
        
        switch cell.isExpanded {
        case true:
            self.expandedRows.remove(post.id)
            
        case false:
            do {
                if self.selectedRowIndex > -1 {
                    guard let oldCell = tableView.cellForRow(at: IndexPath.init(row: self.selectedRowIndex, section: 0)) as? PlaylistCell
                        else { return }
                    
                    oldCell.isExpanded = false
                    self.expandedRows.removeAll()
                    self.selectedRowIndex = -1
                }
                
                self.expandedRows.insert(post.id)
            }
        }
        
        cell.isExpanded = !cell.isExpanded
        
//        if let _url = URL(string: post.audio ) as URL?,
//            cell.isExpanded {
//            DispatchQueue.main.async {
//                let asset = AVURLAsset.init(url: _url)
//                cell.lblElapsedTime.text = "0:00"
//                cell.lblDuration.text = TimeInterval(CMTimeGetSeconds(asset.duration)).durationText
//            }
//        }
        
        self.tvDiagnoses.endUpdates()
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistCell
            else { return }
        
        self.tvDiagnoses.beginUpdates()
        
        let post = PostController.Instance.getFollowingPosts(type: self.postType)[indexPath.row]
        self.expandedRows.remove(post.id)
        cell.isExpanded = false
        
        self.tvDiagnoses.endUpdates()
        
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        return PostController.Instance.getFollowingPosts(type: self.postType).count
    }
    
    //
    // MARK: ExpandableLabel Delegate
    //
    
    func willExpandLabel(_ label: ExpandableLabel) {
        self.tvDiagnoses.beginUpdates()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tvDiagnoses)
        if let indexPath = self.tvDiagnoses.indexPathForRow(at: point) as IndexPath? {
            guard let cell = self.tvDiagnoses.cellForRow(at: indexPath) as? PlaylistCell
                else { return }
            
            let post = PostController.Instance.getFollowingPosts(type: self.postType)[indexPath.row]
            self.states.insert(post.id)
            
            cell.showFullDescription = true
        }
        self.tvDiagnoses.endUpdates()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        self.tvDiagnoses.beginUpdates()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tvDiagnoses)
        if let indexPath = self.tvDiagnoses.indexPathForRow(at: point) as IndexPath? {
            guard let cell = self.tvDiagnoses.cellForRow(at: indexPath) as? PlaylistCell
                else { return }
            
            let post = PostController.Instance.getFollowingPosts(type: self.postType)[indexPath.row]
            self.states.remove(post.id)
            
            cell.showFullDescription = false
        }
        self.tvDiagnoses.endUpdates()
    }
}
