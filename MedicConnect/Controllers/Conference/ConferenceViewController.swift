//
//  ConferenceViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-31.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class ConferenceViewController: BaseViewController {
    
    let CallHistoryCellID = "CallHistoryAudioCell"
    
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var txFieldSearch: UITextField!
    
    @IBOutlet weak var scCallType: UISegmentedControl!
    @IBOutlet var tvHistory: UITableView!
    
    var callHistories: [[String: String]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadData()
    }
    
    //MARK: UI Functions
    
    func initViews() {
        
        // Set Segmented Control font
        let attr = NSDictionary(object: UIFont(name: "Avenir-Black", size: 12.0)!, forKey: NSFontAttributeName as NSCopying)
        UISegmentedControl.appearance().setTitleTextAttributes(attr as [NSObject : AnyObject] , for: .normal)
        
        // Initialize Table Views
        let nib = UINib(nibName: CallHistoryCellID, bundle: nil)
        self.tvHistory.register(nib, forCellReuseIdentifier: CallHistoryCellID)
        self.tvHistory.tableFooterView = UIView()
        
    }
    
    // MARK: Private methods
    
    func loadData() {
        callHistories = [["id": "1",
                          "name": "Dr. Dave Loewen",
                          "initial": "DL",
                          "date": "October 20 2017",
                          "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507784695841"],
                         ["id": "2",
                          "name": "Dr. Evelyn Sporks",
                          "initial": "ES",
                          "date": "October 20 2017"],
                         ["id": "3",
                          "name": "Dr. Jeff Harder",
                          "initial": "JH",
                          "date": "October 20 2017",
                          "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507822955506"],
                         ["id": "4",
                          "name": "Dr. Susan Ross",
                          "initial": "SR",
                          "date": "October 20 2017"],
                         ["id": "5",
                          "name": "Contact",
                          "initial": "C",
                          "date": "October 20 2017"],
                         ["id": "6",
                          "name": "Contact",
                          "initial": "C",
                          "date": "October 20 2017"],
                         ["id": "7",
                          "name": "Contact",
                          "initial": "C",
                          "date": "October 20 2017"]
        ]
        
        self.tvHistory.reloadData()
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        return self.callHistories.count
    }
    
}

extension ConferenceViewController : UITableViewDelegate, UITableViewDataSource {
    
    // MARK: UITableView DataSource Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows(inTableView: tableView, section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CallHistoryAudioCell = tableView.dequeueReusableCell(withIdentifier: CallHistoryCellID) as! CallHistoryAudioCell
        
        // Set cell data
        let _history = self.callHistories[indexPath.row]
        cell.setUserData(user: _history, isAudio: scCallType.selectedSegmentIndex == 1)
        
        return cell
    }
    
    // MARK: UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
    
}

extension ConferenceViewController {
    
    // MARK: IBActions
    
    @IBAction func onSearchTapped(sender: AnyObject) {
        if (!self.txFieldSearch.isFirstResponder) {
            self.txFieldSearch.becomeFirstResponder()
        }
    }
    
    @IBAction func historyTypeChanged(_ sender: Any) {
        self.tvHistory.reloadData()
    }
    
}
