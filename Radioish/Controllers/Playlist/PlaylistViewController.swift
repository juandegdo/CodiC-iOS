
//  PlaylistViewController.swift
//  Radioish
//
//  Created by alessandro on 12/22/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import YLProgressBar
import CoreData
import AVFoundation
import MessageUI

var playlist = [CD_Post]()
var postIndex = [String: Int]()
class PlaylistViewController: BaseViewController, ExpandableLabelDelegate {
    
    let PlayListCellID = "PlaylistItemCell"
    
    @IBOutlet var lblCurrentBroadcastName: UILabel!
    @IBOutlet var lblCurrentBroadcastUsername: UILabel!
    
    @IBOutlet var btnShuffle: UIButton!
    @IBOutlet var btnPrev: UIButton!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnNext: UIButton!
    @IBOutlet var playingProgressBar: YLProgressBar!
    @IBOutlet var tableView: UITableView!
    
    var playType = 0
    var isShuffle = false
    var arrShuffle = [NSInteger]()
    var playingIndex = 0
    var prevIndex : Int?

    var selectedDotsIndex = 0
    var vcDisappearType : ViewControllerDisappearType = .other
    
    let reach = Reachability.forInternetConnection()
    var isReachable = true
    
    var expandedRows = Set<String>()
    var states = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
        reach?.reachableBlock = {
            (reach: Reachability?) -> Void in
            
            DispatchQueue.main.async {
                print("Reachable")
                self.isReachable = true
                self.refreshData()
            }
        }
        
        reach?.unreachableBlock = {
            (reach: Reachability?) -> Void in
            
            DispatchQueue.main.async {
                print("Unreachable")
                self.isReachable = false
                self.refreshData()
            }
        }
        
        reach?.startNotifier()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isReachable {
            PlaylistService.Instance.getPlaylist(completion: { (success: Bool) in
                
                let playlistUsers = PlaylistController.Instance.getPlaylistPosts() 
                
                for post in playlist {
                    // Remove if post does not exist in remote playlist
                    if !playlistUsers.contains(where: { $0.id == post.id }) {
                        PlayListDataController.Instance.deletePost(post: post)
                    }
                    
                }
                
                for post in playlistUsers {
                    // Add if post does not exist in local playlist
                    if !playlist.contains(where: { $0.id == post.id }) {
                        PlayListDataController.Instance.addPost(post: post)
                    }
                }
                
                self.refreshData()
            })
            
        } else {
            self.refreshData()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive , object: nil)
        
        lblCurrentBroadcastName.text = ""
        lblCurrentBroadcastUsername.text = ""
        
        // Set progress bar to default
        self.playingProgressBar.progress = 0;
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let tabvc = self.tabBarController as UITabBarController? {
            DataManager.Instance.setLastTabIndex(tabIndex: tabvc.selectedIndex)
        }
        
        if (vcDisappearType == .other) {
            self.releasePlayer()
            self.btnPlay.isSelected = false
            self.btnPlay.setImage(UIImage.init(named: "icon_playlist_play_on"), for: .normal)
            self.btnPlay.setImage(UIImage.init(named: "icon_playlist_play_off"), for: .highlighted)
            self.btnShuffle.isSelected = false
            isShuffle = false
            playType = 0
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
    }
    
    //MARK: Initialize Views
    func initViews() {
        
        // Initialize Table View
        self.tableView.register(UINib(nibName: PlayListCellID, bundle: nil), forCellReuseIdentifier: PlayListCellID)
        self.tableView.tableFooterView = UIView()
        self.tableView.estimatedRowHeight = 130.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
    }
    
    //MARK: Private Functions
    func refreshData() {
        // Load playlist
        PlayListDataController.Instance.loadPlayList()
        
        // Clear post indexes
        postIndex.removeAll()
        
        let posts = PostController.Instance.getFollowingPosts()
        var flag = true
        for item in playlist {
            flag = true
            for j in 0..<posts.count {
                if posts[j].id == item.id {
                    postIndex[posts[j].id] = j
                    flag = false
                    break
                }
            }
            if flag == true {
                PlayListDataController.Instance.deletePost(post: item)
                if let _index = playlist.index(of: item) {
                    playlist.remove(at:  _index)
                }
            }
        }
        
        var flagForEnable = true
        if playlist.count == 0 {
            flagForEnable = false
        }
        
        btnPlay.isEnabled = flagForEnable
        btnShuffle.isEnabled = flagForEnable
        btnNext.isEnabled = flagForEnable
        btnPrev.isEnabled = flagForEnable
        
        self.tableView.reloadData()
    }
    
    func loadMe() {
        
        UserService.Instance.getMe(completion: {
            (user: User?) in
            
            if let _ = user as User? {
                self.refreshData()
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
                let _index = _lastPlayed.index as Int? {
                let tPost = playlist[_index]
                let post = (isReachable ? PostController.Instance.getFollowingPosts()[postIndex[tPost.id!]!] : convertToPost(post: tPost ) )
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
        PlayerController.Instance.playingProgressBar = nil
        
        //TODO: get current list
        if let _index = PlayerController.Instance.currentIndex as Int? {
            let post = PostController.Instance.getFollowingPosts()[_index]
            post.resetCurrentTime()
        }
        
        PlayerController.Instance.currentIndex = nil
    }
    
    func initializeShuffleArray() {
        if(isShuffle){
            if arrShuffle.count == 0 {
                for i in 0..<playlist.count {
                    arrShuffle.append(i)
                }
            }
        }
    }
    
    // MARK: Selectors
    func onPlayAudio(sender: SVGPlayButton) {
        self.btnPlay.isSelected = true
        self.btnPlay.setImage(UIImage.init(named: "icon_playlist_pause_on"), for: .normal)
        self.btnPlay.setImage(UIImage.init(named: "icon_playlist_pause_off"), for: .highlighted)
        
        guard let _index = sender.index as Int?,
            let _refTableView = sender.refTableView as UITableView? else {
                return
        }
        
        playingIndex = _index
        
        let tPost = playlist[_index]
        let post = (isReachable ? PostController.Instance.getFollowingPosts()[postIndex[tPost.id!]!] : convertToPost(post: tPost ) )
        
        lblCurrentBroadcastName.text = post.title
        lblCurrentBroadcastUsername.text = post.user.fullName
        
        if let _idx = PlayerController.Instance.currentIndex as Int?, _idx != _index {
            self.releasePlayer()
            self.tableView.reloadRows(at: [IndexPath.init(row: _idx, section: 0)], with: .none)
        }else{
            self.releasePlayer(onlyState: true)
        }
        var _playUrl : URL?
        
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let _localUrl = documentsUrl.appendingPathComponent("\(post.user.id).mp4")
        
        if !isReachable { //FileManager.default.fileExists(atPath: _localUrl.path) {
            _playUrl = _localUrl
        }else if let _oUrl = URL(string: post.audio ) as URL? {
            _playUrl = _oUrl
        }
        if let _url = _playUrl {
            if let _player = PlayerController.Instance.player as AVPlayer?,
                let _currentIndex = PlayerController.Instance.currentIndex as Int?, _currentIndex == _index {
                
                PlayerController.Instance.lastPlayed = sender
                PlayerController.Instance.playingProgressBar = self.playingProgressBar
                
                PlayerController.Instance.shouldSeek = false
                _player.rate = 1.0
                PlayerController.Instance.currentTime = CMTime(seconds: 0.0, preferredTimescale: CMTimeScale(1.0)) //post.getCurrentTime()
                print("Playing with current time: \(post.getCurrentTime())")
                _player.play()
                
                PlayerController.Instance.addObserver()
                
            } else {
                
                let playerItem = AVPlayerItem(url: _url)
                PlayerController.Instance.player = AVPlayer(playerItem:playerItem)
                
                if let _player = PlayerController.Instance.player as AVPlayer? {
                    
                    AudioHelper.SetCategory(mode: AVAudioSessionPortOverride.speaker)
                    
                    PlayerController.Instance.lastPlayed = sender
                    PlayerController.Instance.playingProgressBar = self.playingProgressBar
                    PlayerController.Instance.currentIndex = _index
                    
                    _player.rate = 1.0
                    PlayerController.Instance.currentTime = CMTime(seconds: 0.0, preferredTimescale: CMTimeScale(1.0)) //post.getCurrentTime()
                    print("Playing with current time: \(post.getCurrentTime())")
                    _player.play()
                    
                    PlayerController.Instance.addObserver()
                    
                    
                    // Increment play count
                    if isReachable && Float(_player.currentTime().value) == 0.0 {
                        
                        PostService.Instance.incrementPost(id: post.id, completion: { (success, play_count) in
                            if success, let play_count = play_count {
                                print("Post incremented")
                                post.playCount = play_count
                                if let cell = _refTableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? PlaylistItemCell {
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
            
            guard let _index = sender.index as Int?,
                let _ = sender.refTableView as UITableView? else {
                    return
            }
            
            let tPost = playlist[_index]
            let post = (isReachable ? PostController.Instance.getFollowingPosts()[postIndex[tPost.id!]!] : convertToPost(post: tPost ) )
            
            post.setPlayed(time: _player.currentItem!.currentTime(), progress: sender.progressStrokeEnd)
        }
        
        PlayerController.Instance.lastPlayed?.tickCount = 0
        PlayerController.Instance.lastPlayed = nil
        PlayerController.Instance.playingProgressBar = nil
        PlayerController.Instance.shouldSeek = true
        
        PlayerController.Instance.scheduleReset()
        
        
    }
    
    func onPauseAudio(sender: SVGPlayButton) {
        self.btnPlay.isSelected = false
        self.btnPlay.setImage(UIImage.init(named: "icon_playlist_play_on"), for: .normal)
        self.btnPlay.setImage(UIImage.init(named: "icon_playlist_play_off"), for: .highlighted)
        
        guard let _player = PlayerController.Instance.player as AVPlayer? else {
            return
        }
        
        _player.pause()
        PlayerController.Instance.lastPlayed?.tickCount = 0
        PlayerController.Instance.lastPlayed = nil
        PlayerController.Instance.playingProgressBar = nil
        PlayerController.Instance.shouldSeek = true
        
        PlayerController.Instance.scheduleReset()
        
        guard let _index = sender.index as Int?,
            let _ = sender.refTableView as UITableView? else {
                return
        }
        
        let tPost = playlist[_index]
        let post = (isReachable ? PostController.Instance.getFollowingPosts()[postIndex[tPost.id!]!] : convertToPost(post: tPost ) )
        
        post.setPlayed(time: _player.currentItem!.currentTime(), progress: sender.progressStrokeEnd)
    }
    
    func onSelectShare(sender: UIButton) {
        
        self.performSegue(withIdentifier: Constants.SegueRadioishShareBroadcastPopup, sender: nil)
        
    }
    
    func onSelectComment(sender: UIButton) {
        
        let _index = sender.tag
        
        vcDisappearType = .comment
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            
            
            let tPost = playlist[_index]
            let post = (isReachable ? PostController.Instance.getFollowingPosts()[postIndex[tPost.id!]!] : convertToPost(post: tPost ) )
            
            vc.currentPost = post
            self.present(vc, animated: false, completion: nil)
        }
        
    }
    
    func onSelectUser(sender: UITapGestureRecognizer) {
        if let index = sender.view?.tag,
            let post = PostController.Instance.getFollowingPosts()[index] as Post? {
            self.callProfileVC(user: post.user)
        }
    }
    
    func onSelectLikeDescription(sender: UITapGestureRecognizer) {
        vcDisappearType = .like
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "LikesViewController") as? LikesViewController {
            if let index = sender.view?.tag,
                let post = PostController.Instance.getFollowingPosts()[index] as Post? {
                
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
    
    @IBAction func btnShuffleClicked(_ sender: Any) {
        btnShuffle.isSelected = !btnShuffle.isSelected
        isShuffle = btnShuffle.isSelected
    }
    
    @IBAction func btnPrevClicked(_ sender: Any) {
        if isShuffle==true {
            playingIndex = Int(arc4random_uniform(UInt32(playlist.count)))
        }else{
            playingIndex = ((playingIndex > 0) ? (playingIndex - 1) : playlist.count - 1 )//(playingIndex + 1) % playlist.count
        }
        
        playAudioWithType()
    }
    
    @IBAction func btnPlayClicked(_ sender: Any) {
        btnPlay.isSelected = !btnPlay.isSelected
        
        if (btnPlay.isSelected) {
            self.btnPlay.setImage(UIImage.init(named: "icon_playlist_pause_on"), for: .normal)
            self.btnPlay.setImage(UIImage.init(named: "icon_playlist_pause_off"), for: .highlighted)
        } else {
            self.btnPlay.setImage(UIImage.init(named: "icon_playlist_play_on"), for: .normal)
            self.btnPlay.setImage(UIImage.init(named: "icon_playlist_play_off"), for: .highlighted)
        }

        playType = (btnPlay.isSelected ? 1 : 0)
        if(playType == 1){

            if(isShuffle){
                btnNextClicked(UIButton())
            }else{
                playingIndex = 0
                playAudioWithType()
            }
        }else{
            
            if let _idx = PlayerController.Instance.currentIndex as Int? {
                
                self.tableView.reloadRows(at: [IndexPath.init(row: _idx, section: 0)], with: .none)
            }
            pauseAudioWithType()
            
        }
        
    }
    
    @IBAction func btnNextClicked(_ sender: Any) {
        
        if isShuffle {
            if arrShuffle.count == 0 {
                initializeShuffleArray()
            }
            let idx = Int(arc4random_uniform(UInt32(arrShuffle.count)))
            playingIndex = arrShuffle[idx]
            print("\nPlayingIndex = \(playingIndex)\n")
            arrShuffle.remove(at: idx)
            
        }else{
            playingIndex = (playingIndex + 1) % playlist.count
        }
        
        playAudioWithType()
        
    }
    
    func playAudioWithType() {
        let idxPath = IndexPath.init(row: playingIndex, section: 0)
        if(checkIfVisible(withIndexPath: idxPath) == false){
            self.tableView.scrollToRow(at: idxPath, at: .top, animated: false)
        }
        if let cell = self.tableView.cellForRow(at: idxPath) as? PlaylistItemCell {
            onPlayAudio(sender: cell.btnPlay)
            cell.btnPlay.playing = true
        }
    }
    func pauseAudioWithType() {
        let idxPath = IndexPath.init(row: playingIndex, section: 0)
        if(checkIfVisible(withIndexPath: idxPath) == false) {
            self.tableView.scrollToRow(at: idxPath, at: .top, animated: false)
        }
        if let cell = self.tableView.cellForRow(at: idxPath) as? PlaylistItemCell {
            onPauseAudio(sender: cell.btnPlay)
            cell.btnPlay.playing = false
        }
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
}

extension PlaylistViewController : UITableViewDataSource, UITableViewDelegate {
    //MARK: UITableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == self.tableView {
            
            tableView.backgroundView = nil
            return 1
            
        } else {
            
            let bgView: RadTableBackgroundView = RadTableBackgroundView(frame: tableView.bounds)
            bgView.setTitle("No Broadcastings.", caption: "User has no broadcastings to show...")
            tableView.backgroundView = bgView
            return 0
            
        }
        
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        
        if (tableView == self.tableView) {
            if isReachable {
                return postIndex.count;
            } else {
                return playlist.count;
            }
        }
        
        return 0;
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        return self.numberOfRows(inTableView: tableView, section: section)
        
    }
    
    
    func convertToPost(post: CD_Post) -> Post {
        
        let retUser = User(id: post.user_id!, fullName: post.user_fullName!, email: post.user_email!)
        retUser.photo = post.user_photo!
        let retMeta = Meta(createdAt: post.createdAt!)
        
        let retPost = Post(id: post.id!, audio: post.audio!, meta: retMeta, playCount: Int(post.playCount), commentsCount: Int(post.commentsCount), title: post.title!, description: post.postDescription!, user: retUser)
        return retPost
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isReachable {
            let cell: PlaylistItemCell = tableView.dequeueReusableCell(withIdentifier: PlayListCellID) as! PlaylistItemCell
            
            if let pId = playlist[indexPath.row].id, let fIndex = postIndex[pId], fIndex < PostController.Instance.getFollowingPosts().count {
                
                let post = PostController.Instance.getFollowingPosts()[fIndex]
                
                cell.setData(post: post)
                
                cell.btnShare.tag = indexPath.row
                cell.btnShare.addTarget(self, action: #selector(onSelectShare(sender:)), for: .touchUpInside)
                cell.btnShare.isEnabled = true
                
                cell.btnMessage.tag = indexPath.row
                cell.btnMessage.addTarget(self, action: #selector(onSelectComment(sender:)), for: .touchUpInside)
                cell.btnMessage.isEnabled = true
                
                cell.btnPlay.willPlay = { self.onPlayAudio(sender: cell.btnPlay) }
                cell.btnPlay.willPause = { self.onPauseAudio(sender: cell.btnPlay)  }
                cell.btnPlay.index = indexPath.row
                cell.btnPlay.refTableView = tableView
                cell.btnPlay.progressStrokeEnd = 0//post.getCurrentProgress()
                cell.btnPlay.isEnabled = true
                
                if cell.btnPlay.playing {
                    cell.btnPlay.playing = false
                }
                
                cell.btnLike.addTarget(self, action: #selector(onToggleLike(sender:)), for: .touchUpInside)
                cell.btnLike.index = indexPath.row
                cell.btnLike.refTableView = tableView
                cell.btnLike.isEnabled = true
                
                cell.btnAction.addTarget(self, action: #selector(onToggleAction(sender:)), for: .touchUpInside)
                cell.btnAction.index = indexPath.row
                cell.btnAction.refTableView = tableView
                cell.btnAction.isEnabled = true
                
                cell.btnPlaylist.addTarget(self, action: #selector(onTogglePlayList(sender:)), for: .touchUpInside)
                cell.btnPlaylist.index = indexPath.row
                cell.btnPlaylist.refTableView = tableView
                cell.btnPlaylist.setImage(UIImage(named: "icon_broadcast_playlisted"), for: .normal)
                
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
                cell.imgUserAvatar.tag = fIndex
                
                let tapGestureOnUsername = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
                cell.lblUsername.addGestureRecognizer(tapGestureOnUsername)
                cell.lblUsername.tag = fIndex
                
                let isFullDesc = self.states.contains(post.id)
                cell.lblDescription.delegate = self
                cell.lblDescription.shouldCollapse = true
                cell.lblDescription.numberOfLines = isFullDesc ? 0 : 1;
                cell.lblDescription.text = post.description
                cell.lblDescription.collapsed = !isFullDesc
                cell.showFullDescription = isFullDesc
                
                let tapGestureOnLikeDescription = UITapGestureRecognizer(target: self, action: #selector(onSelectLikeDescription(sender:)))
                cell.lblLikedDescription.addGestureRecognizer(tapGestureOnLikeDescription)
                cell.lblLikedDescription.tag = fIndex
                
                let tapGestureOnHashtags = UITapGestureRecognizer(target: self, action: #selector(onSelectHashtag(sender:)))
                cell.txtVHashtags.addGestureRecognizer(tapGestureOnHashtags)
                cell.txtVHashtags.tag = indexPath.row
                
                cell.isExpanded = self.expandedRows.contains(post.id)
                cell.selectionStyle = .none
            }
            return cell
            
        } else {
            
            let cell: PlaylistItemCell = tableView.dequeueReusableCell(withIdentifier: PlayListCellID) as! PlaylistItemCell
            
            let post = convertToPost(post: playlist[indexPath.row])
            
            cell.setData(post: post)
            
            cell.btnShare.isEnabled = false
            cell.btnMessage.isEnabled = false
            cell.btnPlay.willPlay = { self.onPlayAudio(sender: cell.btnPlay) }
            cell.btnPlay.willPause = { self.onPauseAudio(sender: cell.btnPlay)  }
            cell.btnPlay.index = indexPath.row
            cell.btnPlay.refTableView = tableView
            cell.btnPlay.progressStrokeEnd = post.getCurrentProgress()
            
            if cell.btnPlay.playing {
                cell.btnPlay.playing = false
            }
            
            cell.btnLike.isEnabled = false
            cell.btnAction.isEnabled = false
            cell.btnPlaylist.isEnabled = false
            
            let isFullDesc = self.states.contains(post.id)
            cell.lblDescription.delegate = self
            cell.lblDescription.shouldCollapse = true
            cell.lblDescription.numberOfLines = isFullDesc ? 0 : 1;
            cell.lblDescription.text = post.description
            cell.lblDescription.collapsed = !isFullDesc
            cell.showFullDescription = isFullDesc
            
            cell.selectionStyle = .none
            
            return cell
            
        }
    }
    
    func onTogglePlayList(sender: TVButton) {
        guard let _index = sender.index as Int?,
            let _ = sender.refTableView as UITableView? else {
                return
        }
        
        let post = playlist[_index]
        let userId = post.user_id!
        
        if postIndex[post.id!] != nil {
            postIndex.removeValue(forKey: post.id!)
        }
        
        playlist.remove(at: _index)
        PlayListDataController.Instance.deletePost(post: post)
        
        // Delete from remote database
        PlaylistService.Instance.removeUserFromPlaylist(userId: userId, completion: { (success: Bool) in
            if success {
                
            } else {
                NSLog("Failed to save the playlist user on remote db.")
            }
        })
        
        self.refreshData()
        
    }
    
    func onToggleFollowing(sender: TVButton) {
        
        guard let _index = sender.index as Int?,
            let _ = sender.refTableView as UITableView? else {
                return
        }
        
        var userId: String = ""
        
        let tPost = playlist[_index]
        let post = (isReachable ? PostController.Instance.getFollowingPosts()[postIndex[tPost.id!]!] : convertToPost(post: tPost ) )
        
        userId = post.user.id
        
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
    
    
    func onToggleAction(sender: TVButton) {
        guard let _ = sender.index as Int?,
            let _ = sender.refTableView as UITableView? else {
                return
        }
        
        print("\(sender.index!)")
        selectedDotsIndex = sender.index!
        
        let tPost = playlist[selectedDotsIndex]
        let post = (isReachable ? PostController.Instance.getFollowingPosts()[postIndex[tPost.id!]!] : convertToPost(post: tPost ) )
        
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
        
        let tPost = playlist[_index]
        let post = (isReachable ? PostController.Instance.getFollowingPosts()[postIndex[tPost.id!]!] : convertToPost(post: tPost ) )
        
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
                    if let cell = _refTableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? PlaylistItemCell {
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
                    if let cell = _refTableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? PlaylistItemCell {
                        cell.setData(post: post)
                        
                        cell.btnLike.setImage(UIImage(named: "icon_broadcast_liked"), for: .normal)
                        cell.btnLike.tag = 1
                    }
                }
            })
            
        }
        
    }
    
    func checkIfVisible(withIndexPath idxPath: IndexPath) -> Bool{
        if let indexPaths = self.tableView.indexPathsForVisibleRows {
            if indexPaths.contains(idxPath) {
                return true
            }
        }
        return false
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        
        self.releasePlayer()
        
        if playType == 1 {
            btnNextClicked(UIButton())
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isReachable {
            if let pId = playlist[indexPath.row].id, let fIndex = postIndex[pId], fIndex < PostController.Instance.getFollowingPosts().count {
                
                guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistItemCell
                    else { return }
                
                let post = PostController.Instance.getFollowingPosts()[indexPath.row]
                
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
        } else {
            
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if isReachable {
            guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistItemCell
                else { return }
            
            let post = PostController.Instance.getFollowingPosts()[indexPath.row]
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
            guard let cell = self.tableView.cellForRow(at: indexPath) as? PlaylistItemCell
                else { return }
            
            let pId = isReachable ? playlist[indexPath.row].id : convertToPost(post: playlist[indexPath.row]).id
            self.states.insert(pId!)
            
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
            guard let cell = self.tableView.cellForRow(at: indexPath) as? PlaylistItemCell
                else { return }
            
            let pId = isReachable ? playlist[indexPath.row].id : convertToPost(post: playlist[indexPath.row]).id
            self.states.remove(pId!)
            
            cell.showFullDescription = false
        }
        self.tableView.endUpdates()
    }

}
