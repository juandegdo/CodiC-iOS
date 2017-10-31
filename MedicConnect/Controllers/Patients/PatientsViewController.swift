//
//  PatientsViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-16.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import AVFoundation
import MessageUI

import Fabric
import Crashlytics

class PatientsViewController: BaseViewController, UIGestureRecognizerDelegate, ExpandableLabelDelegate {
    
    let PatientCellID = "PatientListCell"
    
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var txFieldSearch: UITextField!
    @IBOutlet var tvPatients: UITableView!
    
    var vcDisappearType : ViewControllerDisappearType = .other
    
    var patients: [[String: String]] = []
    var selectedDotsIndex = 0
    var states = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.initViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadPatients()
        vcDisappearType = .other
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let tabvc = self.tabBarController as UITabBarController? {
            DataManager.Instance.setLastTabIndex(tabIndex: tabvc.selectedIndex)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Private Functions
    
    func initViews() {
        // Initialize Table Views
        
        let nibPatientCell = UINib(nibName: PatientCellID, bundle: nil)
        self.tvPatients.register(nibPatientCell, forCellReuseIdentifier: PatientCellID)
        
        self.tvPatients.tableFooterView = UIView()
        self.tvPatients.estimatedRowHeight = 106.0
        self.tvPatients.rowHeight = UITableViewAutomaticDimension
    }
    
}

extension PatientsViewController {
    
    // MARK: Private methods
    
    func loadPatients() {
        patients = [["id": "1",
                     "patientName": "Patient Name  #1234567890",
                     "description": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                     "doctorName": "Dr. Dave Loewen",
                     "date": "October 20 2017",
                     "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507784695841"],
                    ["id": "2",
                     "patientName": "Patient Name  #1234567890",
                     "description": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                     "doctorName": "Dr. Jeff Harder",
                     "date": "October 20 2017",
                     "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507822955506"],
                    ["id": "3",
                     "patientName": "Patient Name  #1234567890",
                     "description": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                     "doctorName": "Dr. Dave Loewen",
                     "date": "October 20 2017",
                     "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507784695841"],
                    ["id": "4",
                     "patientName": "Patient Name  #1234567890",
                     "description": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                     "doctorName": "Dr. Jeff Harder",
                     "date": "October 20 2017",
                     "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507822955506"],
                    ["id": "5",
                     "patientName": "Patient Name  #1234567890",
                     "description": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                     "doctorName": "Dr. Dave Loewen",
                     "date": "October 20 2017",
                     "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507784695841"]
        ]
        
        self.tvPatients.reloadData()
    }
    
    func onToggleAction(sender: TVButton) {
        guard let _ = sender.index as Int?,
            let _ = sender.refTableView as UITableView? else {
                return
        }
        
        print("\(sender.index!)")
        selectedDotsIndex = sender.index!
//        let post = PostController.Instance.getFollowingPosts()[selectedDotsIndex]
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        let actionReportThisBroadcast = UIAlertAction(title: "Report this broadcast", style: .destructive) { (action) in
//            guard let _user = UserController.Instance.getUser() as User? else {
//                return
//            }
//
//            UserService.Instance.report(from: _user.email, subject: "Report this broadcast", msgbody: "User: \(post.user.fullName)\nUrl: \(post.audio)", completion: { (success) in
//                if success {
//                    DispatchQueue.main.async {
//                        AlertUtil.showOKAlert(self, message: "Thanks for reporting this broadcast.\nWe are looking into it.")
//                    }
//
//            });
        }
        
        let actionReportUser = UIAlertAction(title: "Report this user", style: .destructive) { (action) in
//            guard let _user = UserController.Instance.getUser() as User? else {
//                return
//            }
//
//            UserService.Instance.report(from: _user.email, subject: "Report this user", msgbody: "User: \(post.user.fullName)", completion: { (success) in
//                if success {
//                    DispatchQueue.main.async {
//                        AlertUtil.showOKAlert(self, message: "Thanks for reporting this broadcaster.\nWe are looking into it.")
//                    }
//                }
//            });
        }
        
        let actionBlockUser = UIAlertAction(title: "Block user", style: .default) { (action) in
//            UserService.Instance.block(userId: post.user.id , completion: {
//                (success: Bool) in
//                if success {
//                    DispatchQueue.main.async {
//                        AlertUtil.showOKAlert(self, message: "This user is now blocked.\nGo to Settings to undo this action.")
//                    }
//
//                    self.loadPatients()()
//                } else {
//                    sender.makeEnabled(enabled: true)
//                }
//            })
        }
        
        let actionTurnOnPost = UIAlertAction(title: "Turn on Post notification", style: .default) { (action) in
            
        }
        
        let actionCopyShareUrl = UIAlertAction(title: "Copy Share Url", style: .default) { (action) in
//            UIPasteboard.general.string = post.audio
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
    
    func showPatientProfile(user: User) {
//        if  let _me = UserController.Instance.getUser() as User? {
//            if _me.id == user.id {
//                return
//            }
//
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//
//            if  let vc = storyboard.instantiateViewController(withIdentifier: "AnotherProfileViewController") as? AnotherProfileViewController {
//                if let blockedby = _me.blockedby as? [User] {
//                    if blockedby.contains(where: { $0.id == user.id }) {
//                        return
//                    }
//                }
//
//                if let blocking = _me.blocking as? [User] {
//                    if blocking.contains(where: { $0.id == user.id }) {
//                        return
//                    }
//                }
//
//                vc.currentUser = user
//                self.present(vc, animated: false, completion: nil)
//            }
//        }
        
    }
    
    // MARK: Selectors
    
    func onSelectUser(sender: UITapGestureRecognizer) {
//        let index = sender.view?.tag
//        let post : Post? = PostController.Instance.getFollowingPosts()[index!]
//
//        if (post != nil) {
//            self.callProfileVC(user: (post?.user)!)
//        }
    }
    
}

extension PatientsViewController : UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableView DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        return 1
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        return self.patients.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows(inTableView: tableView, section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PatientListCell = tableView.dequeueReusableCell(withIdentifier: PatientCellID) as! PatientListCell
        
        let data = self.patients[indexPath.row]
        cell.setData(data: data)
        
        cell.btnAction.addTarget(self, action: #selector(onToggleAction(sender:)), for: .touchUpInside)
        cell.btnAction.index = indexPath.row
        cell.btnAction.refTableView = tableView
        
        let tapGestureOnUserAvatar = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
        cell.imgUserPhoto.addGestureRecognizer(tapGestureOnUserAvatar)
        cell.imgUserPhoto.tag = indexPath.row
        
        let tapGestureOnUsername = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
        cell.lblDoctorName.addGestureRecognizer(tapGestureOnUsername)
        cell.lblDoctorName.tag = indexPath.row
        
        let isFullDesc = self.states.contains(data["id"]!)
        cell.lblDescription.delegate = self
        cell.lblDescription.shouldCollapse = true
        cell.lblDescription.numberOfLines = isFullDesc ? 0 : 1;
        cell.lblDescription.text = data["description"]
        cell.lblDescription.collapsed = !isFullDesc
        cell.showFullDescription = isFullDesc
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    // MARK: UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    //
    // MARK: ExpandableLabel Delegate
    //
    
    func willExpandLabel(_ label: ExpandableLabel) {
        self.tvPatients.beginUpdates()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tvPatients)
        if let indexPath = self.tvPatients.indexPathForRow(at: point) as IndexPath? {
            guard let cell = self.tvPatients.cellForRow(at: indexPath) as? PatientListCell
                else { return }
            
            let patient = patients[indexPath.row]
            self.states.insert(patient["id"]!)
            
            cell.showFullDescription = true
        }
        self.tvPatients.endUpdates()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        self.tvPatients.beginUpdates()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tvPatients)
        if let indexPath = self.tvPatients.indexPathForRow(at: point) as IndexPath? {
            guard let cell = self.tvPatients.cellForRow(at: indexPath) as? PatientListCell
                else { return }
            
            let patient = patients[indexPath.row]
            self.states.remove(patient["id"]!)
            
            cell.showFullDescription = false
        }
        self.tvPatients.endUpdates()
    }
}

extension PatientsViewController {
    
    // MARK: IBActions
    
    @IBAction func onSearchTapped(sender: AnyObject) {
        if (!self.txFieldSearch.isFirstResponder) {
            self.txFieldSearch.becomeFirstResponder()
        }
    }
    
    @IBAction func onAddTapped(sender: AnyObject) {
        
    }
    
}
