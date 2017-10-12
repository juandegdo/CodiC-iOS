//
//  ProfileViewController.swift
//  MedicConnect
//
//  Created by alessandro on 11/27/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import AVFoundation
import AlamofireImage
import HTHorizontalSelectionList

class ProfileViewController: BaseViewController, ExpandableLabelDelegate {
    
//    let homeTypes: [String] = ["Following", "Recommended"]
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
    @IBOutlet var lblNotesNumber: UILabel!
    @IBOutlet var lblNotesText: UILabel!
    
    // Scroll
    @IBOutlet var mainScrollView: UIScrollView!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var btnRecord: UIButton!
    
    // Constraints
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var headerViewHeightConstraint: NSLayoutConstraint!
    
    var isDiagnosis: Bool = true
    var vcDisappearType : ViewControllerDisappearType = .other
    
    var expandedRows = Set<String>()
    var states = Set<String>()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show Tutorial Screen
//        if (UserDefaultsUtil.LoadFirstLoad() % 10 == 0) {
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            if let vc = storyboard.instantiateViewController(withIdentifier: "TutorialViewController") as? TutorialViewController {
//                vc.type = .profile
//                self.present(vc, animated: false, completion: nil)
//            }
//            
//            UserDefaultsUtil.SaveFirstLoad(firstLoad: UserDefaultsUtil.LoadFirstLoad() + 1)
//        }
    }
    
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
    
    func updatedProfileSettings() {
        refreshData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.initViews()
        
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
    
    // MARK: Private methods
    
    func initViews() {
        
        self.imgAvatar.layer.borderWidth = 1.5
        self.imgAvatar.layer.borderColor = UIColor.white.cgColor
        
        self.updateUI()
        self.refreshData()
        
    }
    
    func refreshData() {
        
        UserService.Instance.getMe(completion: {
            (user: User?) in
            
            if let _ = user as User? {
                self.updateUI()
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
                
                if let _user = UserController.Instance.getUser() as User? {
                    
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
        
        if let _user = UserController.Instance.getUser() as User?,
            let _index = PlayerController.Instance.currentIndex as Int? {
            let post = _user.getPosts()[_index]
            post.resetCurrentTime()
        }
        
        PlayerController.Instance.currentIndex = nil
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
            self.lblUsername.text = _user.fullName
//            self.lblLocation.text = _user.location
//            self.lblTitle.text = _user.title
            
            // Customize Following/Follower
            self.lblDiagnosisNumber.text  = "\(_user.getPosts().count)"
            self.lblNotesNumber.text  = "\(_user.getPosts().count)"
            
            if self.isDiagnosis {
                self.lblDiagnosisNumber.textColor = Constants.ColorDarkGray4
                self.lblDiagnosisText.textColor = Constants.ColorDarkGray4
                self.lblNotesNumber.textColor = Constants.ColorLightGray1
                self.lblNotesText.textColor = Constants.ColorLightGray1
            } else {
                self.lblDiagnosisNumber.textColor = Constants.ColorLightGray1
                self.lblDiagnosisText.textColor = Constants.ColorLightGray1
                self.lblNotesNumber.textColor = Constants.ColorDarkGray4
                self.lblNotesText.textColor = Constants.ColorDarkGray4
            }
            
        }
        
        self.tableView.reloadData()
        self.updateScroll(offset: self.mainScrollView.contentOffset.y)
        
    }
    
    func onToggleLike(sender: TVButton) {
        
        guard let _index = sender.index as Int? else {
                return
        }
        
        guard let _user = UserController.Instance.getUser() as User? else {
            return
        }
        
        let post = _user.getPosts()[_index]
        
        sender.makeEnabled(enabled: false)
        if sender.tag == 1 {
            PostService.Instance.unlike(postId: post.id, completion: { (success, like_description) in
                sender.makeEnabled(enabled: true)
                
                if success, let like_description = like_description {
                    print("Post succesfully unliked")
                    
                    post.removeLike(id: _user.id)
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
                    
                    post.addLike(id: _user.id)
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
    
    // MARK: Selectors
    
    func onSelectShare(sender: UIButton) {
        
        vcDisappearType = .share
        
        self.performSegue(withIdentifier: Constants.SegueMedicConnectShareBroadcastPopup, sender: nil)
        
    }
    
    func onSelectComment(sender: UIButton) {
        
        vcDisappearType = .comment
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            if let _user = UserController.Instance.getUser() {
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
            if let _user = UserController.Instance.getUser(),
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
    
    func onToggleAction(sender: UIButton) {
        
        print("\(sender.tag)")
        
    }
    
    func onPlayAudio(sender: SVGPlayButton) {
        
        guard let _index = sender.index as Int? else {
            return
        }
        
        guard let _user = UserController.Instance.getUser() as User? else {
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
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
        
        guard let _user = UserController.Instance.getUser() as User? else {
            return
        }
        
        let post = _user.getPosts()[_index]
        post.setPlayed(time: _player.currentItem!.currentTime(), progress: sender.progressStrokeEnd)
        
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        
        self.releasePlayer()
    }
    
    // MARK: Scroll Ralated
    
    func updateScroll(offset: CGFloat) {
        self.viewProfileInfo.alpha = max (0.0, (OffsetHeaderStop - offset) / OffsetHeaderStop)
        
        // ScrollViews Frame
        if (offset >= OffsetHeaderStop) {
            self.tableViewTopConstraint.constant = offset - OffsetHeaderStop + self.headerViewHeightConstraint.constant
            self.tableViewHeightConstraint.constant = self.view.frame.height - 64
            
            self.getCurrentScroll().setContentOffset(CGPoint(x: 0, y: offset - OffsetHeaderStop), animated: false)
        }
        else {
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

    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        
        if (tableView == self.tableView) {
            
            if let _user = UserController.Instance.getUser() as User? {
                return _user.getPosts().count
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
            
            let post = _user.getPosts()[indexPath.row]
            cell.setData(post: post)
            
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
            
            cell.btnLike.isHidden = !self.isDiagnosis
            cell.btnMessage.isHidden = !self.isDiagnosis
            cell.btnAction.isHidden = !self.isDiagnosis
            
            if self.isDiagnosis {
                cell.btnLike.addTarget(self, action: #selector(onToggleLike(sender:)), for: .touchUpInside)
                cell.btnLike.index = indexPath.row
                cell.btnLike.isUserInteractionEnabled = false
                
                if let _user = UserController.Instance.getUser() as User? {
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
            } else {
//                cell.likeBadgeView.isHidden = true
//                cell.commentBadgeView.isHidden = true
            }
            
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            let post = _user.getPosts()[indexPath.row]
            self.expandedRows.remove(post.id)
            
            cell.isExpanded = false
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            if tableView == self.tableView {
                
                if let _user = UserController.Instance.getUser() as User? {
                    
                    let _post = _user.getPosts()[indexPath.row]
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
                else { return }
            
            guard let _user = UserController.Instance.getUser() as User? else {
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
            
            guard let _user = UserController.Instance.getUser() as User? else {
                return
            }
            
            let post = _user.getPosts()[indexPath.row]
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
            
            if offset < 0 { // PULL DOWN -----------------
//                var headerTransform: CATransform3D = CATransform3DIdentity
//                let headerScaleFactor: CGFloat = -(offset) / self.viewProfileInfo.bounds.height
//                let headerSizevariation: CGFloat = ((self.viewProfileInfo.bounds.height * (1.0 + headerScaleFactor)) - self.viewProfileInfo.bounds.height) / 2.0
//                headerTransform = CATransform3DTranslate(headerTransform, 0, headerSizevariation, 0)
//                headerTransform = CATransform3DScale(headerTransform, 1.0 + headerScaleFactor, 1.0 + headerScaleFactor, 0)
                
                // Apply Transformations
//                self.headerView.layer.transform = headerTransform
//                self.viewProfileInfo.layer.transform = CATransform3DIdentity
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.SegueMedicConnectRecordPopup {
            if let popupVC = segue.destination as? RecordPopupViewController {
                popupVC.isDiagnosis = self.isDiagnosis
            }
        }
    }
    
}

extension ProfileViewController {

    //MARK: IBActions
    
    @IBAction func onEditProfile(sender: AnyObject!) {
        self.callEditVC()
    }
    
    @IBAction func onDiagnosisTapped(sender: AnyObject!) {
        self.isDiagnosis = true
        self.updateUI()
    }
    
    @IBAction func onNotesTapped(sender: AnyObject!) {
        self.isDiagnosis = false
        self.updateUI()
    }
    
    @IBAction func onRecord(sender: AnyObject!) {
        vcDisappearType = .record
        self.performSegue(withIdentifier: Constants.SegueMedicConnectRecordPopup, sender: nil)
    }
    
}
