//
//  HomeViewController.swift
//  Radioish
//
//  Created by alessandro on 11/26/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import AVFoundation
import HTHorizontalSelectionList
import MessageUI

import Fabric
import Crashlytics

public enum ViewControllerDisappearType {
    case comment
    case like
    case share
    case playlist
    case other
}

class HomeViewController: BaseViewController, UIGestureRecognizerDelegate, ExpandableLabelDelegate {
    
    @IBOutlet var selectionList: HTHorizontalSelectionList!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var tvFollowings: UITableView!
    @IBOutlet var tvRecommends: UITableView!
    
    let homeTypes: [String] = ["Following", "Recommended"]
    var vcDisappearType : ViewControllerDisappearType = .other
    
    var selectedDotsIndex = 0
    var expandedRows = Set<String>()
    var states = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (UIApplication.shared.applicationIconBadgeNumber > 0) {
            NotificationUtil.updateNotificationAlert(hasNewAlert: true)
        }
        
        // Register Device Token
        if let _me = UserController.Instance.getUser() as User?, let deviceToken = UserController.Instance.getDeviceToken() as String?, deviceToken != _me.deviceToken {
            UserService.Instance.putDeviceToken(deviceToken: deviceToken) { (success) in
                if (success) {
                    _me.deviceToken = deviceToken
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.initViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show Tutorial Screen
        if (UserDefaultsUtil.LoadFirstLoad() / 10 == 0) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "TutorialViewController") as? TutorialViewController {
                vc.type = .home
                self.present(vc, animated: false, completion: nil)
            }
            
            UserDefaultsUtil.SaveFirstLoad(firstLoad: UserDefaultsUtil.LoadFirstLoad() + 10)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadMe()
        self.loadAll()
        
        vcDisappearType = .other
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
        
    }
    
    // MARK: Private Functions
    
    func initViews() {
        
        // Initialize Selection Lists
        
        self.selectionList.delegate = self
        self.selectionList.dataSource = self
        
        self.selectionList.centerButtons = true
        self.selectionList.snapToCenter = true
        self.selectionList.selectionIndicatorHeight = 3
        self.selectionList.selectionIndicatorHorizontalPadding = -1
        
        self.selectionList.backgroundColor = UIColor.clear
        self.selectionList.bottomTrimColor = Constants.ColorDarkGray3
        self.selectionList.selectionIndicatorColor = Constants.ColorRed
        self.selectionList.selectionIndicatorAnimationMode = .noBounce
        
        let selectionListFont: UIFont = UIFont(name: "Avenir-Book", size: 15.0) as UIFont? ?? UIFont.systemFont(ofSize: 15.0)
        self.selectionList.setTitleFont(selectionListFont, for: .normal)
        self.selectionList.setTitleFont(selectionListFont, for: .selected)
        
        let selectionListColor = UIColor(white: 1.0, alpha: 0.4)
        self.selectionList.setTitleColor(selectionListColor, for: .normal)
        self.selectionList.setTitleColor(UIColor.white, for: .selected)
        
        // Initialize Table Views
        
        let nibPlaylistCell = UINib(nibName: Constants.PlaylistCellID, bundle: nil)
        self.tvFollowings.register(nibPlaylistCell, forCellReuseIdentifier: Constants.PlaylistCellID)
        
        let nibFollowerCell = UINib(nibName: Constants.FollowerCellID, bundle: nil)
        self.tvRecommends.register(nibFollowerCell, forCellReuseIdentifier: Constants.FollowerCellID)
        
        self.tvFollowings.tableFooterView = UIView()
        self.tvFollowings.estimatedRowHeight = 125.0
        self.tvFollowings.rowHeight = UITableViewAutomaticDimension
        
        self.tvRecommends.tableFooterView = UIView()
        self.tvRecommends.rowHeight = 88.0
        
    }
    
}

extension HomeViewController {
    
    // MARK: Private methods
    
    /**
     * Get the page frame for index
     */
    func getPageFrame(pageIndex: Int) -> CGRect {
        
        var pageFrame: CGRect = self.scrollView.bounds
        pageFrame.origin.x = CGFloat(pageIndex) * pageFrame.width
        
        return pageFrame
        
    }
    
    func loadPosts() {
        
        // Load Playlist
        PlayListDataController.Instance.loadPlayList()
        
        UserService.Instance.getTimeline(completion: {
            (success: Bool) in
            
            if success {
                self.tvFollowings.reloadData()
            }
            
        })
        
        UserService.Instance.getRecommendedUsers { (success : Bool) in
            
            if success {
                self.tvRecommends.reloadData()
            }
            
        }
        
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
    
    func loadAll() {
        
        UserService.Instance.getAll(name: "", completion: {
            (success: BaseTaskController.Response) in
            
        })
        
        NotificationService.Instance.getNotifications { (success) in
            print("notification: \(success)")
        }
        
        UserService.Instance.getPromotedUsers { (success : Bool) in
            if success {
                let count = UserController.Instance.getPromotedUsers().count
                print("Promoted Content User Counts: \(count)")
            }
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
                let _refTableView = _lastPlayed.refTableView as UITableView?,
                let _index = _lastPlayed.index as Int? {
                
                let post = _refTableView == self.tvFollowings ? PostController.Instance.getFollowingPosts()[_index] : PostController.Instance.getRecommendedPosts()[_index]
                post.setPlayed(time: _player.currentItem!.currentTime(), progress: _lastPlayed.progressStrokeEnd, setLastPlayed: false)
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
        
        //TODO: get current list
        if let _index = PlayerController.Instance.currentIndex as Int? {
            let post = PostController.Instance.getFollowingPosts()[_index]
            post.resetCurrentTime()
        }
        
        PlayerController.Instance.currentIndex = nil
    }
    
    func onPlayAudio(sender: SVGPlayButton) {
        
        guard let _index = sender.index as Int?,
            let _refTableView = sender.refTableView as UITableView? else {
                return
        }
        
        let post = _refTableView == self.tvFollowings ? PostController.Instance.getFollowingPosts()[_index] : PostController.Instance.getRecommendedPosts()[_index]
        
        self.releasePlayer(onlyState: true)
        
        if let _url = URL(string: post.audio ) as URL? {
            if let _player = PlayerController.Instance.player as AVPlayer?,
                let _currentIndex = PlayerController.Instance.currentIndex as Int?, _currentIndex == _index {
                
                PlayerController.Instance.lastPlayed = sender
                
                PlayerController.Instance.shouldSeek = false
                _player.rate = 1.0
                PlayerController.Instance.currentTime = post.getCurrentTime()
                print("Playing with current time: \(post.getCurrentTime())")
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
                    print("Playing with current time: \(post.getCurrentTime())")
                    _player.play()
                    
                    PlayerController.Instance.addObserver()
                    
                    // Increment play count
                    if Float(_player.currentTime().value) == 0.0 {
                        
                        PostService.Instance.incrementPost(id: post.id, completion: { (success, play_count) in
                            if success, let play_count = play_count {
                                print("Post incremented")
                                post.playCount = play_count
                                if let cell = _refTableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? PlaylistCell {
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
            guard let _index = PlayerController.Instance.currentIndex as Int?,
                let _refTableView = sender.refTableView as UITableView? else {
                    return
            }
            
            let post = _refTableView == self.tvFollowings ? PostController.Instance.getFollowingPosts()[_index] : PostController.Instance.getRecommendedPosts()[_index]
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
        
        guard let _index = sender.index as Int?,
            let _refTableView = sender.refTableView as UITableView? else {
                return
        }
        
        let post = _refTableView == self.tvFollowings ? PostController.Instance.getFollowingPosts()[_index] : PostController.Instance.getRecommendedPosts()[_index]
        post.setPlayed(time: _player.currentItem!.currentTime(), progress: sender.progressStrokeEnd)
    }
    
    func onToggleFollowing(sender: TVButton) {
        
        guard let _index = sender.index as Int?,
            let _refTableView = sender.refTableView as UITableView? else {
                return
        }
        
        var userId: String = ""
        
        if (_refTableView == self.tvFollowings) {
            let post = PostController.Instance.getFollowingPosts()[_index]
            userId = post.user.id
            
        } else {
            let user = UserController.Instance.getRecommendedUsers()[_index]
            userId = user.id
        }
        
        sender.makeEnabled(enabled: false)
        if sender.tag == 0 {
            
            UserService.Instance.follow(userId: userId, completion: {
                (success: Bool) in
                
                if success {
                    self.loadMe()
                } else {
                    sender.makeEnabled(enabled: true)
                }
                
            })
            
        } else {
            
            UserService.Instance.unfollow(userId: userId, completion: {
                (success: Bool) in
                
                if success {
                    self.loadMe()
                } else {
                    sender.makeEnabled(enabled: true)
                }
                
            })
            
        }
        
    }
    
    
    
    func onTogglePlayList(sender: TVButton) {
        sender.isEnabled = false
        
        guard let _index = sender.index as Int?,
            let _refTableView = sender.refTableView as UITableView? else {
                return
        }
        
        var userId: String = ""
        
        if (_refTableView == self.tvFollowings) {
            let post = PostController.Instance.getFollowingPosts()[_index]
            userId = post.user.id
            
            PlayListDataController.Instance.loadPlayList()
            if !playlist.contains(where: { $0.user_id == userId }) {
                PlayListDataController.Instance.addPost(post: post)
                PlayListDataController.Instance.loadPlayList()
                _refTableView.reloadData()
            }
            
        } else {
            let user = UserController.Instance.getRecommendedUsers()[_index]
            userId = user.id
        }
        sender.isEnabled = true
    }
    
    func onToggleAction(sender: TVButton) {
        guard let _ = sender.index as Int?,
            let _ = sender.refTableView as UITableView? else {
                return
        }
        
        print("\(sender.index!)")
        selectedDotsIndex = sender.index!
        let post = PostController.Instance.getFollowingPosts()[selectedDotsIndex]
        
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
        
        let post = PostController.Instance.getFollowingPosts()[_index]
        
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
    
    func playerDidFinishPlaying(note: NSNotification) {
        
        self.releasePlayer()
        
    }
    
    func callProfileVC(user: User) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if  let _me = UserController.Instance.getUser() as User?,
            let vc = storyboard.instantiateViewController(withIdentifier: "AnotherProfileViewController") as? AnotherProfileViewController {
            
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
            vc.isMyProfile = (_me.id == user.id)
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
    
    func onSelectShare(sender: UIButton) {
        
        vcDisappearType = .share
        
        self.performSegue(withIdentifier: Constants.SegueRadioishShareBroadcastPopup, sender: nil)
        
    }
    
    func onSelectComment(sender: UIButton) {
        vcDisappearType = .comment
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            var post : Post?
            if (selectionList.selectedButtonIndex == 0) {
                post = PostController.Instance.getFollowingPosts()[sender.tag]
            } else {
                post = PostController.Instance.getRecommendedPosts()[sender.tag]
            }
            
            vc.currentPost = post
            self.present(vc, animated: false, completion: nil)
        }
        
    }
    
    func onSelectUser(sender: UITapGestureRecognizer) {
        let index = sender.view?.tag
        var post : Post?
        
        if (selectionList.selectedButtonIndex == 0) {
            post = PostController.Instance.getFollowingPosts()[index!]
        } else {
            post = PostController.Instance.getRecommendedPosts()[index!]
        }
        
        if (post != nil) {
            self.callProfileVC(user: (post?.user)!)
        }
    }
    
    func onSelectLikeDescription(sender: UITapGestureRecognizer) {
        vcDisappearType = .like
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "LikesViewController") as? LikesViewController {
            let index = sender.view?.tag
            var post : Post?
            
            if (selectionList.selectedButtonIndex == 0) {
                post = PostController.Instance.getFollowingPosts()[index!]
            } else {
                post = PostController.Instance.getRecommendedPosts()[index!]
            }
            
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

extension HomeViewController : UIScrollViewDelegate{
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let pageWidth: CGFloat = self.scrollView.frame.size.width
        let targetContentOffsetX = targetContentOffset.pointee.x
        let fractionalPage: Float = Float(targetContentOffsetX) / Float(pageWidth)
        let page = lroundf(fractionalPage)
        
        if(scrollView.contentOffset.x != 0) {
            self.selectionList.setSelectedButtonIndex(page, animated: true)
            self.scrollView.scrollRectToVisible(self.getPageFrame(pageIndex: page), animated: true)
        }
    }
}

extension HomeViewController : HTHorizontalSelectionListDataSource, HTHorizontalSelectionListDelegate {
    // MARK: HTHorizontalSelectionListDataSource Methods
    func numberOfItems(in selectionList: HTHorizontalSelectionList) -> Int {
        return self.homeTypes.count
    }
    
    func selectionList(_ selectionList: HTHorizontalSelectionList, titleForItemWith index: Int) -> String? {
        return self.homeTypes[index]
    }
    
    // MARK: HTHorizontalSelectionListDataSource Methods
    func selectionList(_ selectionList: HTHorizontalSelectionList, didSelectButtonWith index: Int) {
        self.scrollView.scrollRectToVisible(self.getPageFrame(pageIndex: index), animated: true)
    }
}

extension HomeViewController : UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableView DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.tvFollowings {
            tableView.backgroundView = nil
            return 1
        } else if tableView == self.tvRecommends {
            tableView.backgroundView = nil
            return 1
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows(inTableView: tableView, section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if tableView == self.tvFollowings {
            
            let cell: PlaylistCell = tableView.dequeueReusableCell(withIdentifier: Constants.PlaylistCellID) as! PlaylistCell
            
            let post = PostController.Instance.getFollowingPosts()[indexPath.row]
            cell.setData(post: post)
            
            cell.btnShare.tag = indexPath.row
            cell.btnShare.addTarget(self, action: #selector(onSelectShare(sender:)), for: .touchUpInside)
            
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
            cell.btnLike.refTableView = tableView
            
            cell.btnAction.addTarget(self, action: #selector(onToggleAction(sender:)), for: .touchUpInside)
            cell.btnAction.index = indexPath.row
            cell.btnAction.refTableView = tableView
            
            cell.btnPlaylist.addTarget(self, action: #selector(onTogglePlayList(sender:)), for: .touchUpInside)
            cell.btnPlaylist.index = indexPath.row
            cell.btnPlaylist.refTableView = tableView
            
            if let _user = UserController.Instance.getUser() as User? {
                let hasLiked = post.hasLiked(id: _user.id)
                let image = hasLiked ? UIImage(named: "icon_broadcast_liked") : UIImage(named: "icon_broadcast_like")
                cell.btnLike.setImage(image, for: .normal)
                cell.btnLike.tag = hasLiked ? 1 : 0
                
                let hasCommented = post.hasCommented(id: _user.id)
                let image1 = hasCommented ? UIImage(named: "icon_broadcast_messaged") : UIImage(named: "icon_broadcast_message")
                cell.btnMessage.setImage(image1, for: .normal)
                
                let hasAddedToPlaylist = playlist.contains(where: { $0.id == post.id })
                let image2 = hasAddedToPlaylist ? UIImage(named: "icon_broadcast_playlisted") : UIImage(named: "icon_broadcast_playlist")
                cell.btnPlaylist.setImage(image2, for: .normal)
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
            
            let cell: FollowerCell = tableView.dequeueReusableCell(withIdentifier: Constants.FollowerCellID) as! FollowerCell
            
            // Set button actions
            
            cell.btnFollowing.tag = 1
            cell.btnFollowing.index = indexPath.row
            cell.btnFollowing.refTableView = tableView
            cell.btnFollowing.addTarget(self, action: #selector(onToggleFollowing(sender:)), for: .touchUpInside)
            cell.btnFollowing.makeEnabled(enabled: true)
            
            cell.btnUnFollow.tag = 0
            cell.btnUnFollow.index = indexPath.row
            cell.btnUnFollow.refTableView = tableView
            cell.btnUnFollow.addTarget(self, action: #selector(onToggleFollowing(sender:)), for: .touchUpInside)
            cell.btnUnFollow.makeEnabled(enabled: true)
            
            // Set cell data
            
            if let _recommendedUser = UserController.Instance.getRecommendedUsers()[indexPath.row] as User? {
                cell.setFollowData(user: _recommendedUser)
            }
            
            return cell
        }
        
    }
    
    // MARK: UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.tvFollowings {
            
            guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistCell
                else { return }
            
            let post = PostController.Instance.getFollowingPosts()[indexPath.row]
            
            switch cell.isExpanded {
            case true:
                self.expandedRows.remove(post.id)
                
            case false:
                self.expandedRows.insert(post.id)
            }
            
            cell.isExpanded = !cell.isExpanded
            
            self.tvFollowings.beginUpdates()
            self.tvFollowings.endUpdates()
            
        } else {
            
            tableView.deselectRow(at: indexPath, animated: false)
            
            let user = UserController.Instance.getRecommendedUsers()[indexPath.row]
            self.callProfileVC(user: user)
            
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if tableView == self.tvFollowings {
            
            guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistCell
                else { return }
            
            let post = PostController.Instance.getFollowingPosts()[indexPath.row]
            self.expandedRows.remove(post.id)
            
            cell.isExpanded = false
            
            self.tvFollowings.beginUpdates()
            self.tvFollowings.endUpdates()
            
        }
        
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        if inTableView == self.tvFollowings {
            return PostController.Instance.getFollowingPosts().count
        } else {
            return UserController.Instance.getRecommendedUsers().count
        }
        
    }
    
    //
    // MARK: ExpandableLabel Delegate
    //
    
    func willExpandLabel(_ label: ExpandableLabel) {
        self.tvFollowings.beginUpdates()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tvFollowings)
        if let indexPath = self.tvFollowings.indexPathForRow(at: point) as IndexPath? {
            guard let cell = self.tvFollowings.cellForRow(at: indexPath) as? PlaylistCell
                else { return }
            
            let post = PostController.Instance.getFollowingPosts()[indexPath.row]
            self.states.insert(post.id)

            cell.showFullDescription = true
        }
        self.tvFollowings.endUpdates()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        self.tvFollowings.beginUpdates()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tvFollowings)
        if let indexPath = self.tvFollowings.indexPathForRow(at: point) as IndexPath? {
            guard let cell = self.tvFollowings.cellForRow(at: indexPath) as? PlaylistCell
                else { return }
            
            let post = PostController.Instance.getFollowingPosts()[indexPath.row]
            self.states.remove(post.id)
            
            cell.showFullDescription = false
        }
        self.tvFollowings.endUpdates()
    }
}
