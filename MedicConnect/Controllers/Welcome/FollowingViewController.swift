//
//  FollowingViewController.swift
//  MedicConnect
//
//  Created by alessandro on 11/27/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import HTHorizontalSelectionList

class FollowingViewController: BaseViewController {
    
    let FollowingCellID = "FollowingCell"
    
    @IBOutlet var selectionList: HTHorizontalSelectionList!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var tvFollowings: UITableView!
    @IBOutlet var tvFollowers: UITableView!
    @IBOutlet var btnBackWidthConstraint: NSLayoutConstraint!
    
    var followTypes: [String] = ["Followers", "Following"]
    var isDefaultFollowers: Bool = false
    var currentUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Scroll the scrollview
        if self.isDefaultFollowers {
            let pageIndex = 1
            self.selectionList.selectedButtonIndex = pageIndex
            self.scrollView.scrollRectToVisible(self.getPageFrame(pageIndex: pageIndex), animated: false)
        }
        
    }
    
    //MARK: UI Functions
    
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
        
        let nib = UINib(nibName: FollowingCellID, bundle: nil)
        self.tvFollowings.register(nib, forCellReuseIdentifier: FollowingCellID)
        self.tvFollowers.register(nib, forCellReuseIdentifier: FollowingCellID)
        self.tvFollowings.tableFooterView = UIView()
        self.tvFollowers.tableFooterView = UIView()
        
    }
    
    // MARK: Private methods
    
    func loadData() {
        if (self.currentUser == nil) {
            UserService.Instance.getMe(completion: {
                (user: User?) in
                
                if let _ = user as User? {
                    self.tvFollowings.reloadData()
                    self.tvFollowers.reloadData()
                }
            })
        }
        
    }
    
    /**
     * Get the page frame for index
     */
    func getPageFrame(pageIndex: Int) -> CGRect {
        
        var pageFrame: CGRect = self.scrollView.bounds
        pageFrame.origin.x = CGFloat(pageIndex) * pageFrame.width
        
        return pageFrame
        
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        
        if let _currentUser = self.currentUser as User? {
            
            if inTableView == self.tvFollowings {
                return _currentUser.following.count
            } else {
                return _currentUser.follower.count
            }
            
        } else if let _me = UserController.Instance.getUser() as User? {
            
            if inTableView == self.tvFollowings {
                return _me.following.count
            } else {
                return _me.follower.count
            }
            
        } else {
            
            return 0
            
        }
        
    }
    
    /**
     Returns user for specific UITableView and index.
     
     - Parameter inTableView: UITableView user belongs
     - Parameter times: Index from UITableView user belongs
     
     - Returns: User or nil, if not found.
     */
    func getUserForRow(inTableView: UITableView, row: Int) -> User? {
        
        if let _currentUser = self.currentUser as User? {
            
            if inTableView == self.tvFollowings && row < _currentUser.following.count {
                return _currentUser.following[row] as? User
            } else if inTableView == self.tvFollowers && row < _currentUser.follower.count {
                return _currentUser.follower[row] as? User
            } else {
                return nil
            }
            
        } else if let _me = UserController.Instance.getUser() as User? {
            
            if inTableView == self.tvFollowings && row < _me.following.count {
                return _me.following[row] as? User
            } else if inTableView == self.tvFollowers && row < _me.follower.count {
                return _me.follower[row] as? User
            } else {
                return nil
            }
            
        } else {
            
            return nil
            
        }
        
    }
    
    /**
      - Gets index and UITableView reference from button to identify correct user.
      - Sends *follow* request to server.
      - Updates reference UITableView if request is successful.
     
     - Parameter sender: Button containing user information.
    */
    func setFollow(sender: TVButton) {
        
        sender.makeEnabled(enabled: false)
        
        if let _index = sender.index as Int?,
            let _tableView = sender.refTableView as UITableView?,
            let _user = self.getUserForRow(inTableView: _tableView, row: _index) as User? {
            
            UserService.Instance.follow(userId: _user.id, completion: {
                (success: Bool) in
                
                if success {
                    
                    // If in Following list, just set button state locally, as it's better for UX.
                    // Otherwise, reload data.
                    if _tableView == self.tvFollowings {
                        
                        let cell = _tableView.cellForRow(at: IndexPath(row: _index, section: 0)) as! FollowingCell
                        cell.toggleFollowData()
                        sender.makeEnabled(enabled: true)
                        
                    } else {
                        
                        self.loadData()
                        
                    }
                    
                }
                
            })
            
        }
    }
    
    /**
     - Gets index and UITableView reference from button to identify correct user.
     - Sends *unfollow* request to server.
     - Updates reference UITableView if request is successful.
     
     - Parameter sender: Button containing user information.
     */
    func setUnfollow(sender: TVButton) {
        
        sender.makeEnabled(enabled: false)
        
        if let _index = sender.index as Int?,
            let _tableView = sender.refTableView as UITableView?,
            let _user = self.getUserForRow(inTableView: _tableView, row: _index) as User? {
            
            UserService.Instance.unfollow(userId: _user.id, completion: {
                (success: Bool) in
                
                if success {
                    
                    // If in Following list, just set button state locally, as it's better for UX.
                    // Otherwise, reload data.
                    if _tableView == self.tvFollowings {
                        
                        let cell = _tableView.cellForRow(at: IndexPath(row: _index, section: 0)) as! FollowingCell
                        cell.toggleFollowData()
                        sender.makeEnabled(enabled: true)
                        
                    }
                    self.loadData()
                }
                
            })
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
    
}

extension FollowingViewController : HTHorizontalSelectionListDelegate, HTHorizontalSelectionListDataSource {

    // MARK: HTHorizontalSelectionListDataSource Methods
    
    func numberOfItems(in selectionList: HTHorizontalSelectionList) -> Int {
        
        return self.followTypes.count
        
    }
    
    func selectionList(_ selectionList: HTHorizontalSelectionList, titleForItemWith index: Int) -> String? {
        
        return self.followTypes[index]
        
    }
    
    // MARK: HTHorizontalSelectionListDataSource Methods
    
    func selectionList(_ selectionList: HTHorizontalSelectionList, didSelectButtonWith index: Int) {
        
        self.scrollView.scrollRectToVisible(self.getPageFrame(pageIndex: index), animated: true)
        
    }
}

extension FollowingViewController : UIScrollViewDelegate {
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

extension FollowingViewController : UITableViewDelegate, UITableViewDataSource {

    // MARK: UITableView DataSource Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == self.tvFollowings {
            tableView.backgroundView = nil
            return 1
        } else if tableView == self.tvFollowers {
            tableView.backgroundView = nil
            return 1
        }
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return numberOfRows(inTableView: tableView, section: section)
        
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: FollowingCell = tableView.dequeueReusableCell(withIdentifier: FollowingCellID) as! FollowingCell
        
        // Set button actions
        
        cell.btnFollowing.index = indexPath.row
        cell.btnFollowing.refTableView = tableView
        cell.btnFollowing.addTarget(self, action: #selector(FollowingViewController.setUnfollow(sender:)), for: .touchUpInside)
        cell.btnFollowing.makeEnabled(enabled: true)
        
        cell.btnUnFollow.index = indexPath.row
        cell.btnUnFollow.refTableView = tableView
        cell.btnUnFollow.addTarget(self, action: #selector(FollowingViewController.setFollow(sender:)), for: .touchUpInside)
        cell.btnUnFollow.makeEnabled(enabled: true)
        
        // Set cell data
        
        if tableView == self.tvFollowings {
            
            if let _followingUser = self.getUserForRow(inTableView: tableView, row: indexPath.row) as User? {
                cell.setFollowData(user: _followingUser)
            }
            
        } else if tableView == self.tvFollowers {
            
            if let _followerUser = self.getUserForRow(inTableView: tableView, row: indexPath.row) as User? {
                cell.setFollowData(user: _followerUser)
            }
            
        }
        
        return cell
        
    }
    
    // MARK: UITableView Delegate Methods

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        if tableView == self.tvFollowings {
            
            if let _followingUser = self.getUserForRow(inTableView: tableView, row: indexPath.row) as User? {
                self.callProfileVC(user: _followingUser)
            }
            
        } else if tableView == self.tvFollowers {
            
            if let _followerUser = self.getUserForRow(inTableView: tableView, row: indexPath.row) as User? {
                self.callProfileVC(user: _followerUser)
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tvFollowings || tableView == self.tvFollowers {
            return 88.0
        }
        
        return 0.0
        
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tvFollowings || tableView == self.tvFollowers {
            return 88.0
        }
        
        return 0.0
    }

}

extension FollowingViewController {
    
    // MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject!) {
        
        self.dismiss(animated: false, completion: nil)
        
    }
    
}
