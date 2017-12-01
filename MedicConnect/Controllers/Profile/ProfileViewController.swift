//
//  ProfileViewController.swift
//  MedicConnect
//
//  Created by alessandro on 11/27/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import AVFoundation

class ProfileViewController: BaseViewController, ExpandableLabelDelegate {
    
    let OffsetHeaderStop: CGFloat = 240.0
    let ProfileListCellID = "ProfileListCell"
    
    // Header
    @IBOutlet var headerLabel: UILabel!
    
    // Profile info
    @IBOutlet var viewProfileInfo: UIView!
    @IBOutlet var imgAvatar: UIImageView!
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var lblLocation: UILabel!
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDiagnosisNumber: UILabel!
    @IBOutlet var lblDiagnosisText: UILabel!
    @IBOutlet var lblConsultNumber: UILabel!
    @IBOutlet var lblConsultText: UILabel!
    
    // Scroll
    @IBOutlet var mainScrollView: UIScrollView!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var btnRecord: UIButton!
    
    // Constraints
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var headerViewHeightConstraint: NSLayoutConstraint!
    
    var postType: String = "Diagnosis"
    var vcDisappearType : ViewControllerDisappearType = .other
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
        
        // Initialize Table Views
        self.tableView.register(UINib(nibName: ProfileListCellID, bundle: nil), forCellReuseIdentifier: ProfileListCellID)
        self.tableView.tableFooterView = UIView()
        self.tableView.estimatedRowHeight = 110.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        let nc = NotificationCenter.default
        
        nc.addObserver(self, selector: #selector(self.updatedProfileSettings), name: updatedProfileNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.initViews()
        
        vcDisappearType = .other
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PlayerController.Instance.player?.currentItem)
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
        
        self.imgAvatar.layer.borderWidth = 1.5
        self.imgAvatar.layer.borderColor = UIColor.white.cgColor
        
        self.updateUI()
        self.refreshData()
        self.loadAll()
        
    }
    
    func loadAll() {
        
        UserService.Instance.getAll(name: "", completion: {
            (success: BaseTaskController.Response) in
            
        })
        
        NotificationService.Instance.getNotifications { (success) in
            print("notification: \(success)")
        }
        
    }
    
    func refreshData() {
        
        UserService.Instance.getMe(completion: {
            (user: User?) in
            
            if let _ = user as User? {
                self.updateUI()
            }
        })
        
    }
    
    func updatedProfileSettings() {
        refreshData()
    }
    
    func updateUI() {
        
        if let _user = UserController.Instance.getUser() as User? {
            
            // Customize Avatar
            _ = UIFont(name: "Avenir-Heavy", size: 18.0) as UIFont? ?? UIFont.systemFont(ofSize: 18.0)
            
            if let imgURL = URL(string: _user.photo) as URL? {
                self.imgAvatar.af_setImage(withURL: imgURL)
            } else {
                self.imgAvatar.image = nil
            }
            
            // Customize User information
            self.lblUsername.text = "Dr. \(_user.fullName)"
            self.lblLocation.text = _user.location
            self.lblTitle.text = _user.title
            
            // Customize Following/Follower
            self.lblDiagnosisNumber.text  = "\(_user.getPosts(type: "Diagnosis").count)"
            self.lblConsultNumber.text  = "\(_user.getPosts(type: "Consult").count)"
            
            if self.postType == "Diagnosis" {
                self.lblDiagnosisNumber.textColor = Constants.ColorDarkGray4
                self.lblDiagnosisText.textColor = Constants.ColorDarkGray4
                self.lblConsultNumber.textColor = Constants.ColorLightGray1
                self.lblConsultText.textColor = Constants.ColorLightGray1
            } else {
                self.lblDiagnosisNumber.textColor = Constants.ColorLightGray1
                self.lblDiagnosisText.textColor = Constants.ColorLightGray1
                self.lblConsultNumber.textColor = Constants.ColorDarkGray4
                self.lblConsultText.textColor = Constants.ColorDarkGray4
            }
            
        }
        
        self.tableView.reloadData()
        self.updateScroll(offset: self.mainScrollView.contentOffset.y)
        
    }
    
    func releasePlayer(onlyState: Bool = false) {
        
        PlayerController.Instance.invalidateTimer()
        
        // Reset player state
        if let _lastPlayed = PlayerController.Instance.lastPlayed as PlaySlider?,
            let _elapsedLabel = PlayerController.Instance.elapsedTimeLabel as UILabel? {
            _lastPlayed.setValue(0.0, animated: false)
            _lastPlayed.playing = false
            _elapsedLabel.text = "0:00"
        }
        
        if let _observer = PlayerController.Instance.playerObserver as Any? {
            PlayerController.Instance.player?.removeTimeObserver(_observer)
            PlayerController.Instance.playerObserver = nil
            PlayerController.Instance.player?.seek(to: kCMTimeZero)
        }
        
        if let _user = UserController.Instance.getUser() as User?,
            let _index = PlayerController.Instance.currentIndex as Int? {
            let post = _user.getPosts(type: self.postType)[_index]
            post.setPlayed(time: kCMTimeZero, progress: 0.0, setLastPlayed: false)
            
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? ProfileListCell
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
        PlayerController.Instance.currentIndex = nil
        
    }
    
    func onPlayAudio(sender: UIButton) {
        
        guard let _index = sender.tag as Int? else {
            return
        }
        
        guard let _user = UserController.Instance.getUser() as User? else {
            return
        }
        
        if let _lastPlayed = PlayerController.Instance.lastPlayed,
            _lastPlayed.playing == true {
            self.onPauseAudio(sender: sender)
            return
        }
        
        let post = _user.getPosts(type: self.postType)[_index]
        
        if let _url = URL(string: post.audio ) as URL? {
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: _index, section: 0)) as? ProfileListCell
            sender.setImage(UIImage.init(named: "icon_playlist_pause"), for: .normal)
            
            if let _player = PlayerController.Instance.player as AVPlayer?,
                let _currentIndex = PlayerController.Instance.currentIndex as Int?, _currentIndex == _index {
                
                PlayerController.Instance.lastPlayed = cell?.playSlider
                PlayerController.Instance.elapsedTimeLabel = cell?.lblElapsedTime
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            let post = _user.getPosts(type: self.postType)[_index]
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            let post = _user.getPosts(type: self.postType)[_index]
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            let post = _user.getPosts(type: self.postType)[_index]
            post.setPlayed(time: _player.currentItem!.currentTime(), progress: CGFloat(sender.value))
        }
        
        PlayerController.Instance.lastPlayed?.setValue(Float(0.0), animated: false)
        PlayerController.Instance.lastPlayed = nil
        PlayerController.Instance.elapsedTimeLabel?.text = "0:00"
        PlayerController.Instance.elapsedTimeLabel = nil
        PlayerController.Instance.shouldSeek = true
        PlayerController.Instance.scheduleReset()
        
    }
    
    // MARK: Scroll Ralated
    
    func updateScroll(offset: CGFloat) {
        self.viewProfileInfo.alpha = max (0.0, (OffsetHeaderStop - offset) / OffsetHeaderStop)
        
        // ScrollViews Frame
        if (offset >= OffsetHeaderStop) {
            self.tableViewTopConstraint.constant = offset - OffsetHeaderStop + self.headerViewHeightConstraint.constant
            self.tableViewHeightConstraint.constant = self.view.frame.height - 64
            
            self.getCurrentScroll().setContentOffset(CGPoint(x: 0, y: offset - OffsetHeaderStop), animated: false)
        } else {
            self.tableViewTopConstraint.constant = self.headerViewHeightConstraint.constant
            self.tableViewHeightConstraint.constant = self.view.frame.height - 64 - self.headerViewHeightConstraint.constant + offset
            self.getCurrentScroll().setContentOffset(CGPoint.zero, animated: false)
        }
        
    }
    
    func getCurrentScroll() -> UIScrollView {
        
        let scrollView: UIScrollView = self.tableView
        self.mainScrollView.contentSize = CGSize(width: self.view.frame.width, height: max(self.view.frame.height - 64.0 + OffsetHeaderStop, scrollView.contentSize.height + self.headerViewHeightConstraint.constant))
        return scrollView
        
    }

    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        
        if (tableView == self.tableView) {
            if let _user = UserController.Instance.getUser() as User? {
                return _user.getPosts(type: self.postType).count
            } else {
                return 0
            }
        }
        
        return 0
        
    }
    
}

extension ProfileViewController : UITableViewDataSource, UITableViewDelegate {

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
            
            let cell: ProfileListCell = tableView.dequeueReusableCell(withIdentifier: ProfileListCellID, for: indexPath) as! ProfileListCell
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return cell
            }
            
            let post = _user.getPosts(type: self.postType)[indexPath.row]
            cell.setData(post: post)
            
            let isFullDesc = self.states.contains(post.id)
            cell.lblDescription.delegate = self
            cell.lblDescription.shouldCollapse = true
            cell.lblDescription.numberOfLines = isFullDesc ? 0 : 1;
            cell.lblDescription.text = post.description
            cell.lblDescription.collapsed = !isFullDesc
            cell.showFullDescription = isFullDesc
            
            cell.btnPlay.tag = indexPath.row
            if cell.btnPlay.allTargets.count == 0 {
                cell.btnPlay.addTarget(self, action: #selector(ProfileViewController.onPlayAudio(sender:)), for: .touchUpInside)
            }
            
            cell.btnBackward.tag = indexPath.row
            if cell.btnBackward.allTargets.count == 0 {
                cell.btnBackward.addTarget(self, action: #selector(ProfileViewController.onBackwardAudio(sender:)), for: .touchUpInside)
            }
            
            cell.btnForward.tag = indexPath.row
            if cell.btnForward.allTargets.count == 0 {
                cell.btnForward.addTarget(self, action: #selector(ProfileViewController.onForwardAudio(sender:)), for: .touchUpInside)
            }
            
            cell.playSlider.index = indexPath.row
            cell.playSlider.setValue(Float(post.getCurrentProgress()), animated: false)
            if cell.playSlider.allTargets.count == 0 {
                cell.playSlider.addTarget(self, action: #selector(ProfileViewController.onSeekSlider(sender:)), for: .valueChanged)
            }
            
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            self.releasePlayer()
            self.tableView.beginUpdates()

            let post = _user.getPosts(type: self.postType)[indexPath.row]
            
            switch cell.isExpanded {
            case true:
                self.expandedRows.remove(post.id)
                
            case false:
                self.expandedRows.insert(post.id)
            }
            
            cell.isExpanded = !cell.isExpanded
            
            if let _url = URL(string: post.audio ) as URL?,
                cell.isExpanded {
                DispatchQueue.main.async {
                    let asset = AVURLAsset.init(url: _url)
                    cell.lblElapsedTime.text = "0:00"
                    cell.lblDuration.text = TimeInterval(CMTimeGetSeconds(asset.duration)).durationText
                }
            }
            
            self.tableView.endUpdates()
        }
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView {
            guard let cell = tableView.cellForRow(at: indexPath) as? ProfileListCell
                else { return }
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            self.tableView.beginUpdates()
            
            let post = _user.getPosts(type: self.postType)[indexPath.row]
            self.expandedRows.remove(post.id)
            cell.isExpanded = false
            
            self.tableView.endUpdates()
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            if tableView == self.tableView {
                if let _user = UserController.Instance.getUser() as User? {
                    self.releasePlayer()
                    
                    let _post = _user.getPosts(type: self.postType)[indexPath.row]
                    PostService.Instance.deletePost(id: _post.id, completion: {
                        (success: Bool) in
                    })
                    
                    let _ = UserController.Instance.deletePost(id: _post.id)
                    tableView.setEditing(false, animated: true)
                    self.tableView.reloadData()
                    
                }
            }
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
                else { self.tableView.endUpdates(); return }
            
            guard let _user = UserController.Instance.getUser() as User? else {
                self.tableView.endUpdates()
                return
            }
            
            let post = _user.getPosts(type: self.postType)[indexPath.row]
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
                else { self.tableView.endUpdates(); return }
            
            guard let _user = UserController.Instance.getUser() as User? else {
                self.tableView.endUpdates()
                return
            }
            
            let post = _user.getPosts(type: self.postType)[indexPath.row]
            self.states.remove(post.id)
            
            cell.showFullDescription = false
        }
        self.tableView.endUpdates()
    }
    
}

extension ProfileViewController : UIScrollViewDelegate {

    // MARK: UIScrollViewDelegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == self.mainScrollView {
            let offset: CGFloat = scrollView.contentOffset.y
            
            if offset >= 0 { // SCROLL UP/DOWN ------------
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

extension ProfileViewController {

    //MARK: IBActions
    
    @IBAction func onDiagnosisTapped(sender: AnyObject!) {
        if (self.postType == "Consult") {
            self.postType = "Diagnosis"
            self.expandedRows = Set<String>()
            self.states = Set<String>()
            
            self.releasePlayer()
            self.updateUI()
        }
    }
    
    @IBAction func onConsultsTapped(sender: AnyObject!) {
        if (self.postType == "Diagnosis") {
            self.postType = "Consult"
            self.expandedRows = Set<String>()
            self.states = Set<String>()
            
            self.releasePlayer()
            self.updateUI()
        }
    }
    
    @IBAction func onRecord(sender: AnyObject!) {
        vcDisappearType = .record
        self.releasePlayer()
        
        self.performSegue(withIdentifier: Constants.SegueMedicConnectRecordPopup, sender: nil)
    }
    
}
