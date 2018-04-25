//
//  ConferenceViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-31.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import IQKeyboardManager

class ConferenceViewController: BaseViewController, UIGestureRecognizerDelegate {
    
    let HistoryCellID = "HistoryListCell"
    
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var txFieldSearch: UITextField!
    @IBOutlet var tvHistory: UITableView!
    
    @IBOutlet var constOfTableViewBottom: NSLayoutConstraint!
    
    var vcDisappearType : ViewControllerDisappearType = .other
    var searchedHistory: [History] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        vcDisappearType = .other
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let badgeValue = self.navigationController?.tabBarItem.badgeValue == nil ? 0 : Int((self.navigationController?.tabBarItem.badgeValue)!)!
        UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber > badgeValue ? UIApplication.shared.applicationIconBadgeNumber - badgeValue : 0
        
        self.navigationController?.tabBarItem.badgeValue = nil
        UserDefaultsUtil.SaveMissedCalls("")
        
        self.loadHistory()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        if let tabvc = self.tabBarController as UITabBarController? {
            DataManager.Instance.setLastTabIndex(tabIndex: tabvc.selectedIndex)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Clear search field and results
        self.txFieldSearch.text = ""
        self.loadSearchResult(self.txFieldSearch.text!)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.initViews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ConferenceViewController {
    
    // MARK: Private methods
    
    func initViews() {
        // Initialize Table Views
        
        let nibPatientCell = UINib(nibName: HistoryCellID, bundle: nil)
        self.tvHistory.register(nibPatientCell, forCellReuseIdentifier: HistoryCellID)
        
        self.tvHistory.tableFooterView = UIView()
        self.tvHistory.rowHeight = 65.0
//        self.tvHistory.estimatedRowHeight = 65.0
//        self.tvHistory.rowHeight = UITableViewAutomaticDimension
        
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let bottomMargin = keyboardSize.height - 55.0
            constOfTableViewBottom.constant = bottomMargin
            
            UIView.animate(withDuration: notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        constOfTableViewBottom.constant = 0
        
        UIView.animate(withDuration: notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func loadHistory() {
        // Load History

        HistoryService.Instance.getCallHistory { (success: Bool) in
            self.loadSearchResult(self.txFieldSearch.text!)
        }
        
    }
    
    func loadSearchResult(_ keyword: String) {
        // Local search
        if keyword == "" {
            searchedHistory = HistoryController.Instance.getHistories()
        } else {
            searchedHistory = HistoryController.Instance.getHistories().filter({(history: History) -> Bool in
                return history.fromUser.fullName.lowercased().contains(keyword.lowercased()) ||
                    history.fromUser.location.lowercased().contains(keyword.lowercased())
            })
        }
        
        self.tvHistory.reloadData()
    }
    
    // MARK: Selectors
    
    
}

extension ConferenceViewController : UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableView DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        return 1
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        return self.searchedHistory.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows(inTableView: tableView, section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: HistoryListCell = tableView.dequeueReusableCell(withIdentifier: HistoryCellID) as! HistoryListCell
        let history = self.searchedHistory[indexPath.row]
        
        cell.setData(history)
        
//        let tapGestureOnUserAvatar = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
//        cell.imgUserPhoto.addGestureRecognizer(tapGestureOnUserAvatar)
//        cell.imgUserPhoto.tag = indexPath.row
        
//        let tapGestureOnUsername = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
//        cell.lblDoctorName.addGestureRecognizer(tapGestureOnUsername)
//        cell.lblDoctorName.tag = indexPath.row
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    // MARK: UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
//        guard let _patient = self.searchedPatients[indexPath.row] as Patient? else {
//            return
//        }
//
//        let patientProfileVC = self.storyboard!.instantiateViewController(withIdentifier: "PatientProfileViewController") as! PatientProfileViewController
//        patientProfileVC.patient = _patient
//        patientProfileVC.fromAdd = false
//        self.navigationController?.pushViewController(patientProfileVC, animated: true)
        
    }
    
}

extension ConferenceViewController {
    
    // MARK: IBActions
    
    @IBAction func onSearchTapped(sender: AnyObject) {
        if (!self.txFieldSearch.isFirstResponder) {
            self.txFieldSearch.becomeFirstResponder()
        }
    }
    
}

extension ConferenceViewController : UITextFieldDelegate {
    // UITextfield delegate methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var txtAfterUpdate: NSString =  NSString(string: self.txFieldSearch.text!)
        txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
        txtAfterUpdate = txtAfterUpdate.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        
        if (CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: txtAfterUpdate as String)) && txtAfterUpdate.length > Constants.MaxPHNLength) {
            return false
        }
        
        self.loadSearchResult(txtAfterUpdate as String)
        
        return true
    }
    
}
