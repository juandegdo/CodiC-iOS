//
//  SearchResultsViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-09-21.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import AVFoundation

class SearchResultsViewController: BaseViewController, ExpandableLabelDelegate {
    
    let SearchPostCellID = "PlaylistCell"
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var tvPosts: UITableView!
    
    var hashtag : String = ""
    var selectedDotsIndex = 0
    var expandedRows = Set<String>()
    var states = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LikeController.Instance.setPostLikes([])
        
        initViews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadPosts()
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive , object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
        self.releasePlayer()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Clear hashtag posts
        PostController.Instance.setHashtagPosts([])
    }
    
    //MARK: Initialize Views
    
    func initViews() {
        // Set title
        self.lblTitle.text = self.hashtag
        
        // Initialize Table View
        self.tvPosts.register(UINib(nibName: SearchPostCellID, bundle: nil), forCellReuseIdentifier: SearchPostCellID)
        self.tvPosts.tableFooterView = UIView()
        self.tvPosts.estimatedRowHeight = 125.0
        self.tvPosts.rowHeight = UITableViewAutomaticDimension
        
    }
    
    //MARK: Functions
    
    func loadPosts() {
        PostService.Instance.getPostsFromHashtag(hashtag: self.hashtag, completion: { (success : Bool) in
            if (success) {
                self.tvPosts.reloadData()
            }
        })
    }
    
    func releasePlayer(onlyState: Bool = false) {
        
        PlayerController.Instance.invalidateTimer()
        
        // Reset player state
        if let _lastPlayed = PlayerController.Instance.lastPlayed as SVGPlayButton? {
            _lastPlayed.tickCount = 0
            _lastPlayed.playing = false
            PlayerController.Instance.shouldSeek = true
            
            if let _player = PlayerController.Instance.player as AVPlayer?,
//                let _refTableView = _lastPlayed.refTableView as UITableView?,
                let _index = _lastPlayed.index as Int? {
                
                let post = PostController.Instance.getHashtagPosts()[_index]
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
            let post = PostController.Instance.getHashtagPosts()[_index]
            post.resetCurrentTime()
        }
        
        PlayerController.Instance.currentIndex = nil
    }
    
    func willEnterBackground() {
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        _player.pause()
        
        
        if let sender = PlayerController.Instance.lastPlayed {
            sender.playing = false
            guard let _index = PlayerController.Instance.currentIndex as Int?,
                let _ = sender.refTableView as UITableView? else {
                    return
            }
            
            let post = PostController.Instance.getHashtagPosts()[_index]
            post.setPlayed(time: _player.currentItem!.currentTime(), progress: sender.progressStrokeEnd)
            
        }
        
        PlayerController.Instance.lastPlayed?.tickCount = 0
        PlayerController.Instance.lastPlayed = nil
        PlayerController.Instance.shouldSeek = true
        
        PlayerController.Instance.scheduleReset()
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
}

extension SearchResultsViewController {
    
    //MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func onPlayAudio(sender: SVGPlayButton) {
        
        guard let _index = sender.index as Int?,
            let _refTableView = sender.refTableView as UITableView? else {
                return
        }
        
        let post = PostController.Instance.getHashtagPosts()[_index]
        
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
            let _ = sender.refTableView as UITableView? else {
                return
        }
        
        let post = PostController.Instance.getHashtagPosts()[_index]
        post.setPlayed(time: _player.currentItem!.currentTime(), progress: sender.progressStrokeEnd)
    }
    
    func onToggleAction(sender: TVButton) {
        guard let _ = sender.index as Int?,
            let _ = sender.refTableView as UITableView? else {
                return
        }
        
        print("\(sender.index!)")
        selectedDotsIndex = sender.index!
        let post = PostController.Instance.getHashtagPosts()[selectedDotsIndex]
        
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
                    
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        if (user as User?) != nil {
                            self.loadPosts()
                        }
                    })
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
        
        let post = PostController.Instance.getHashtagPosts()[_index]
        
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
    
    // MARK: Selectors
    
    func onSelectShare(sender: UIButton) {
        
        self.performSegue(withIdentifier: Constants.SegueMedicConnectShareBroadcastPopup, sender: nil)
        
    }
    
    func onSelectComment(sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            let post : Post? = PostController.Instance.getHashtagPosts()[sender.tag]
            
            vc.currentPost = post
            self.present(vc, animated: false, completion: nil)
        }
        
    }
    
    func onSelectUser(sender: UITapGestureRecognizer) {
        let index = sender.view?.tag
        
        guard let post = PostController.Instance.getHashtagPosts()[index!] as Post? else {
            return
        }
        
        self.callProfileVC(user: post.user)
    }
    
    func onSelectLikeDescription(sender: UITapGestureRecognizer) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "LikesViewController") as? LikesViewController {
            let index = sender.view?.tag
            let post : Post? = PostController.Instance.getHashtagPosts()[index!]
            
            if (post != nil) {
                vc.currentPost = post
                self.present(vc, animated: false, completion: nil)
            }
        }
    }
    
}

extension SearchResultsViewController : UITableViewDataSource, UITableViewDelegate{
    //MARK: UITableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PostController.Instance.getHashtagPosts().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tvPosts {
            
            let cell: PlaylistCell = tableView.dequeueReusableCell(withIdentifier: SearchPostCellID) as! PlaylistCell
            
            let post = PostController.Instance.getHashtagPosts()[indexPath.row]
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
                
//                let hasAddedToPlaylist = playlist.contains(where: { $0.id == post.id })
//                let image2 = hasAddedToPlaylist ? UIImage(named: "icon_broadcast_playlisted") : UIImage(named: "icon_broadcast_playlist")
//                cell.btnPlaylist.setImage(image2, for: .normal)
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
            
            cell.isExpanded = self.expandedRows.contains(post.id)
            cell.selectionStyle = .none
            
            return cell
            
        }
        
        return UITableViewCell()
        
    }
    
    // MARK: UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.tvPosts {
            
            guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistCell
                else { return }
            
            let post = PostController.Instance.getHashtagPosts()[indexPath.row]
            
            switch cell.isExpanded {
            case true:
                self.expandedRows.remove(post.id)
                
            case false:
                self.expandedRows.insert(post.id)
            }
            
            cell.isExpanded = !cell.isExpanded
            
            self.tvPosts.beginUpdates()
            self.tvPosts.endUpdates()
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if tableView == self.tvPosts {
            
            guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistCell
                else { return }
            
            let post = PostController.Instance.getHashtagPosts()[indexPath.row]
            self.expandedRows.remove(post.id)
            
            cell.isExpanded = false
            
            self.tvPosts.beginUpdates()
            self.tvPosts.endUpdates()
            
        }
        
    }
    
    //
    // MARK: ExpandableLabel Delegate
    //
    
    func willExpandLabel(_ label: ExpandableLabel) {
        self.tvPosts.beginUpdates()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tvPosts)
        if let indexPath = self.tvPosts.indexPathForRow(at: point) as IndexPath? {
            guard let cell = self.tvPosts.cellForRow(at: indexPath) as? PlaylistCell
                else { return }
            
            let post = PostController.Instance.getHashtagPosts()[indexPath.row]
            self.states.insert(post.id)
            
            cell.showFullDescription = true
        }
        self.tvPosts.endUpdates()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        self.tvPosts.beginUpdates()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tvPosts)
        if let indexPath = self.tvPosts.indexPathForRow(at: point) as IndexPath? {
            guard let cell = self.tvPosts.cellForRow(at: indexPath) as? PlaylistCell
                else { return }
            
            let post = PostController.Instance.getHashtagPosts()[indexPath.row]
            self.states.remove(post.id)
            
            cell.showFullDescription = false
        }
        self.tvPosts.endUpdates()
    }
}

