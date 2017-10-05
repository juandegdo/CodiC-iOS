//
//  SearchViewController.swift
//  Radioish
//
//  Created by alessandro on 12/29/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import IQDropDownTextField
import ERJustifiedFlowLayout
import PICollectionPageView

public enum SearchOption {
    case none
    case recommended
    case listening
    case trending
    case newuploading
}

class SearchViewController: BaseViewController{
    
    let SearchBroadcastCellID = "SearchBroadcastCell"
    let TagCellID = "TagSelectCell"
    
    let SearchPeopleCellID = "SearchPeopleCell"
    let SearchTagCellID = "SearchTagCell"
    let SearchPlaceCellID = "SearchPlaceCell"
    
    @IBOutlet var viewPlayer: UIView!
    @IBOutlet var lblBroadcastname: UILabel!
    @IBOutlet var lblUsername: UILabel!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnPause: UIButton!
    
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var txFieldSearch: UITextField!
    
    @IBOutlet var mainScrollView: UIScrollView!
    @IBOutlet var pageScroll: EVTTabPageScrollView!
    
    @IBOutlet var cvBroadCasts: PICollectionPageView!
    @IBOutlet var btnPrev: UIButton!
    @IBOutlet var btnNext: UIButton!
    @IBOutlet var cvTags: UICollectionView!
    @IBOutlet var customJustifiedFlowLayout: ERJustifiedFlowLayout!
    @IBOutlet var tfCategory: IQDropDownTextField!
    
    @IBOutlet var cvTagsHeightConstraint: NSLayoutConstraint!
    
    // UITableViews
    var tvPeople: UITableView!
    var tvTags: UITableView!
    var tvPlaces: UITableView!
    
    // data
    var userArr: [User] = []
    var placeArr: [String] = []
    
    var searchTimer: Timer?
    var playerStatus: Int = Constants.BrodcastPlayerStatus.None
    var searchOption : SearchOption = .none
    var searchTabIndex: Int = 0
    var tabLoads: [Bool] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        self.updatePlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        PostService.Instance.getTrendingHashtags(completion: { (success : Bool) in
            if success {
//                self.cvTags.layoutIfNeeded()
                self.cvTags.reloadData()
                self.cvTagsHeightConstraint.constant = self.customJustifiedFlowLayout.collectionViewContentSize.height
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clear search field
        self.txFieldSearch.text = ""
        self.view.endEditing(true)
        
        if let tabvc = self.tabBarController as UITabBarController? {
            DataManager.Instance.setLastTabIndex(tabIndex: tabvc.selectedIndex)
        }
        
    }
    
    //MARK: Private methods
    
    func initViews() {
        // Initialize views
        self.tvPeople = UITableView()
        self.tvPeople.dataSource = self
        self.tvPeople.delegate = self
        self.tvPeople.register(UINib(nibName: SearchPeopleCellID, bundle: nil), forCellReuseIdentifier: SearchPeopleCellID)
        self.tvPeople.tableFooterView = UIView.init(frame: .zero)
        
        self.tvTags = UITableView()
        self.tvTags.dataSource = self
        self.tvTags.delegate = self
        self.tvTags.register(UINib(nibName: SearchTagCellID, bundle: nil), forCellReuseIdentifier: SearchTagCellID)
        self.tvTags.tableFooterView = UIView.init(frame: .zero)
        
        self.tvPlaces = UITableView()
        self.tvPlaces.dataSource = self
        self.tvPlaces.delegate = self
        self.tvPlaces.register(UINib(nibName: SearchPlaceCellID, bundle: nil), forCellReuseIdentifier: SearchPlaceCellID)
        self.tvPlaces.tableFooterView = UIView.init(frame: .zero)
        
        let parameter = EVTTabPageScrollViewParameter()
        parameter.indicatorColor = Constants.ColorRed
        parameter.indicatorWidthFactor = 1.0
        parameter.indicatorHeight = 3
        parameter.separatorColor = UIColor(white: 0.85, alpha: 0.5)
        
        let pageItems = [EVTTabPageScrollViewPageItem(tabName: "PEOPLE", andTabView: self.tvPeople), EVTTabPageScrollViewPageItem(tabName: "TAGS", andTabView: self.tvTags), EVTTabPageScrollViewPageItem(tabName: "PLACES", andTabView: self.tvPlaces)] as [Any]
        self.pageScroll = EVTTabPageScrollView(pageItems: pageItems, with: parameter)
        self.pageScroll.delegate = self
        
        for _ in 1...pageItems.count {
            self.tabLoads.append(false)
        }
        
        // Update button text colors and font
        let tabButtons = self.pageScroll.value(forKey: "tabButtons") as! [UIButton]
        for button in tabButtons {
            button.setTitleColor(Constants.ColorDarkGray, for: .normal)
            button.setTitleColor(Constants.ColorTabSelected, for: .selected)
            button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 12)
        }
        
        let rootView = self.view;
        rootView?.addSubview(self.pageScroll)
        
        self.pageScroll.frame = CGRect(x: mainScrollView.frame.origin.x, y: mainScrollView.frame.origin.y, width: (rootView?.frame.width)!, height: mainScrollView.frame.size.height - 104.0)
        self.pageScroll.isHidden = true
        
        // Hide player & Show search
        self.showPlayer(show: false)
        
        // Broadcast collection views
        self.cvBroadCasts.register(UINib(nibName: SearchBroadcastCellID, bundle: nil), forCellWithReuseIdentifier: SearchBroadcastCellID)
        self.cvBroadCasts.reloadData()
        
        // Tag collection views
        self.cvTags.register(UINib(nibName: TagCellID, bundle: nil), forCellWithReuseIdentifier: TagCellID)
        self.customJustifiedFlowLayout.horizontalJustification = FlowLayoutHorizontalJustification.left
        self.customJustifiedFlowLayout.horizontalCellPadding = 10
        self.customJustifiedFlowLayout.sectionInset = UIEdgeInsets.zero
        
//        self.cvTags.layoutIfNeeded()
//        self.cvTags.reloadData()
//
//        self.cvTagsHeightConstraint.constant = self.customJustifiedFlowLayout.collectionViewContentSize.height
        
        // Category
        self.tfCategory.isOptionalDropDown = true
        self.tfCategory.optionalItemText = NSLocalizedString("Choose a category", comment: "comment")
        self.tfCategory.itemList = ["London", "Joannesburg", "Moscow", "Mumbai", "Tokyo", "Sydney"]
        
        self.txFieldSearch.delegate = self
        
    }
    
    func loadData(searchTimer: Timer) {
        
        if let _ = searchTimer.userInfo as? String {
            
            UserService.Instance.getAll(name: "", completion: {
                (success: BaseTaskController.Response) in
                
                if success == BaseTaskController.Response.success {
                    self.tvPeople.reloadData()
                }
            })
        }
    }
    
    func refreshData() {
        
        UserService.Instance.getMe(completion: {
            (user: User?) in
            
            if let _ = user as User? {
                self.tvPeople.reloadData()
            }
        })
        
    }
    
    func loadSearchTab(_ keyword: String) {
        if self.searchTabIndex == 0 {
            // Local search
            self.userArr = UserController.Instance.searchForUsers(string: keyword)
            self.tvPeople.reloadData()
            
        } else if self.searchTabIndex == 1 {
            SearchService.Instance.searchHashtags(keyword: keyword, completion: {
                (success: Bool) in
                if success == true {
                    self.tvTags.reloadData()
                }
            })
            
        } else if self.searchTabIndex == 2 {
            self.placeArr = UserController.Instance.searchForPlaces(string: keyword)
            self.tvPlaces.reloadData()
            
        }
    }
    
    /**
     Returns user for specific UITableView and index.
     
     - Parameter inTableView: UITableView user belongs
     - Parameter times: Index from UITableView user belongs
     
     - Returns: User or nil, if not found.
     */
    func getUserForRow(inTableView: UITableView, row: Int) -> User? {
        
        if row >= self.userArr.count {
            return nil
        }
        
        if let _user = self.userArr[row] as User?, inTableView == self.tvPeople {
            return _user
        } else {
            return nil
        }
        
    }
    
    // MARK: Selectors
    func selectBroadcastToPlay(sender: UIButton) {
        self.playBroadcastWithIndex(index: sender.tag)
    }
    
    func selectTag(sender: UIButton) {
        
    }
    
    //MARK: Functions
    
    func playBroadcastWithIndex(index: Int) {
        self.playerStatus = Constants.BrodcastPlayerStatus.Playing
        self.updatePlayer()
        self.showPlayer(show: true)
    }
    
    func showPlayer(show: Bool) {
        self.mainScrollView.isHidden = !show
        self.pageScroll.isHidden = show
    }
    
    func updatePlayer() {
        self.btnPlay.isHidden = self.playerStatus == Constants.BrodcastPlayerStatus.Playing
        self.btnPause.isHidden = !(self.playerStatus == Constants.BrodcastPlayerStatus.Playing)
    }
    
    func setPlayerData(broadcast: Broadcast) {
        broadcast.isPlaying = true
        self.lblBroadcastname.text = broadcast.broadcastName
        self.lblUsername.text = "\(NSLocalizedString("By:", comment: "comment")) \(broadcast.userName)"
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
            vc.hashtag = hashtag
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    //MARK: ScrollView delegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
}

extension SearchViewController : PICollectionPageViewDataSource, PICollectionPageViewDelegate {
    //Mark - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.cvTags {
            return PostController.Instance.getTrendingHashtags().count
        }
        
        return 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.cvTags {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCellID, for: indexPath) as! TagSelectCell
            cell.setTagTitle(tagTitle: "#\(PostController.Instance.getTrendingHashtags()[indexPath.row])")
            cell.tagButton.tag = indexPath.row
            cell.tagButton.addTarget(self, action: #selector(selectTag(sender:)), for: .touchUpInside)
            return cell
            
        } else if collectionView == self.cvBroadCasts {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchBroadcastCellID, for: indexPath) as! SearchBroadcastCell
            cell.setBroadcastData(UserController.Instance.getPromotedUsers()[indexPath.row])
            return cell
            
        }
        
        return UICollectionViewCell()
        
    }
    
    //Mark - UICollectionViewFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == self.cvTags {
            
            let string = "#\(PostController.Instance.getTrendingHashtags()[indexPath.row])" as NSString
            let tagRect = string.size(attributes: [NSFontAttributeName : UIFont(name: "Avenir-Book", size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)])
            return CGSize(width: tagRect.width + 10, height: 18)
            
        } else if collectionView == self.cvBroadCasts {
            
            return CGSize(width:self.view.frame.width, height: 180)
            
        }
        
        return CGSize.zero
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.cvBroadCasts {
            if let _user = UserController.Instance.getPromotedUsers()[indexPath.row] as User? {
                self.callProfileVC(user: _user)
            }
        }
    }
    
    //MARK: PICollectionPageViewDataSource
    
    func numberOfPage(in pageView: PICollectionPageView!) -> Int {
        
        if pageView == self.cvBroadCasts {
            return UserController.Instance.getPromotedUsers().count
        }
        
        return 0
    }
    
    func pageView(_ pageView: PICollectionPageView!, completeDisplayPageAt index: Int) {
        
        self.showPlayer(show: true)
        self.btnPrev.isHidden = false
        self.btnNext.isHidden = false
        
        if index == 0 {
            self.btnPrev.isHidden = true
        } else if index == pageView.numberOfPages - 1 {
            self.btnNext.isHidden = true
        }
    }
    
    func pageViewCurrentIndexDidChanged(_ pageView: PICollectionPageView!) {
        let _ = IndexPath(row: self.cvBroadCasts.currentPageIndex, section: 0)
    }
}

extension SearchViewController : UITableViewDelegate, UITableViewDataSource {
    
    // Mark: UITableView delegate methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tvPeople {
            return self.userArr.count
            
        } else if tableView == self.tvTags {
            return SearchController.Instance.getHashtags().count
            
        } else if tableView == self.tvPlaces {
            return self.placeArr.count
            
        }
        
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if tableView == self.tvPeople {
            if let _user = self.userArr[indexPath.row] as User? {
                self.callProfileVC(user: _user)
            }
            
        } else if tableView == self.tvTags {
            if let _hashtag = SearchController.Instance.getHashtags()[indexPath.row] as String? {
                self.callSearchResultVC(hashtag: _hashtag)
            }
            
        } else if tableView == self.tvPlaces {
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (tableView == self.tvPeople) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchPeopleCellID) as! SearchPeopleCell
            
            // Set cell data
            if let _user = self.userArr[indexPath.row] as User? {
                cell.setPeopleData(user: _user)
            }
            
            //TODO: create a method to reset cell if user wasn't found. apply to other app cells as well.
            
            return cell
            
        } else if (tableView == self.tvTags) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchTagCellID) as! SearchTagCell
            
            // Set cell data
            if let _hashtag = SearchController.Instance.getHashtags()[indexPath.row] as String? {
                cell.setHashtagData(hashtag: _hashtag)
            }
            
            return cell
            
        } else if (tableView == self.tvPlaces) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchPlaceCellID) as! SearchPlaceCell
            
            return cell
            
        }
        
        return UITableViewCell()
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tvPeople {
            return 88.0
            
        } else if tableView == self.tvTags {
            return 48.0
            
        } else if tableView == self.tvPlaces {
            return 0
            
        }
        
        return 0
        
    }
    
}

extension SearchViewController : EVTTabPageScrollViewDelegate {
    func evtTabPageScrollView(_ tabPageScrollView: EVTTabPageScrollView!, didPageItemSelected pageItem: EVTTabPageScrollViewPageItem!, withTabIndex tabIndex: Int) {
        self.searchTabIndex = tabIndex
        
        if self.tabLoads[tabIndex] == false {
            self.tabLoads[tabIndex] = true
            self.loadSearchTab(self.txFieldSearch.text!)
        }
    }
}

extension SearchViewController {
    
    // Mark: IBActions
    
    @IBAction func onSearch(sender: AnyObject) {
        if (!self.txFieldSearch.isFirstResponder) {
            self.txFieldSearch.becomeFirstResponder()
        }
    }
    
    @IBAction func onPrev(sender: AnyObject) {
        self.cvBroadCasts.scrollToPage(at: max(self.cvBroadCasts.currentPageIndex - 1, 0), animated: true)
    }
    
    @IBAction func onNext(sender: AnyObject) {
        self.cvBroadCasts.scrollToPage(at: min(self.cvBroadCasts.currentPageIndex + 1, self.cvBroadCasts.numberOfPages - 1), animated: true)
    }
    
    @IBAction func onPlay(sender: AnyObject) {
        
        self.cvBroadCasts.reloadData()
        
        self.playerStatus = Constants.BrodcastPlayerStatus.Playing
        self.playBroadcastWithIndex(index: self.cvBroadCasts.currentPageIndex)
    }
    
    @IBAction func onPause(sender: AnyObject) {
        
        self.cvBroadCasts.reloadData()
        
        self.playerStatus = Constants.BrodcastPlayerStatus.Paused
        self.updatePlayer()
        
    }
    
    @IBAction func onRecommended(_ sender: Any) {
        /***** Pending
         
        let _sender = sender as! UIButton
        _sender.makeEnabled(enabled: false)
        
        UserService.Instance.getRecommendedUsers { (success: Bool) in
            if (success) {
                self.userArr = UserController.Instance.getRecommendedUsers()
                self.tvPeople.reloadData()
                self.showPlayer(show: false)
            }
            
            _sender.makeEnabled(enabled: true)
        }
         
        *********/
    }
    
    @IBAction func onWhatWeAreListening(_ sender: Any) {
        
    }
    
    @IBAction func onTrending(_ sender: Any) {
        
    }
    
    @IBAction func onNewUpcoming(_ sender: Any) {
        
    }
    
}

extension SearchViewController : UITextFieldDelegate {
    // UITextfield delegate methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async {
            self.showPlayer(show: false)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var txtAfterUpdate: NSString =  NSString(string: self.txFieldSearch.text!)
        txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
        txtAfterUpdate = txtAfterUpdate.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        
//        self.showPlayer(show: txtAfterUpdate.length == 0)
        
        // Remote search
//        if txtAfterUpdate.length > 0 {
//            self.searchTimer?.invalidate()
//            self.searchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(SearchViewController.loadData(searchTimer:)), userInfo: txtAfterUpdate as String, repeats: false)
//        }
        
        self.loadSearchTab(txtAfterUpdate as String)
        
        for index in 0...self.tabLoads.count - 1 {
            self.tabLoads[index] = self.searchTabIndex == index ? true : false
        }
        
        return true
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.showPlayer(show: textField.text?.characters.count == 0)
    }
    
}
