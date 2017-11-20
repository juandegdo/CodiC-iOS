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
    var searchedPatients: [[String: String]] = []
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
                     "patientName": "Patient Name  #2340238234",
                     "description": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                     "doctorName": "Dr. Jeff Harder",
                     "date": "October 20 2017",
                     "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507822955506"],
                    ["id": "3",
                     "patientName": "Patient Name  #549430284",
                     "description": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                     "doctorName": "Dr. Dave Loewen",
                     "date": "October 20 2017",
                     "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507784695841"],
                    ["id": "4",
                     "patientName": "Patient Name  #734390439",
                     "description": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                     "doctorName": "Dr. Jeff Harder",
                     "date": "October 20 2017",
                     "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507822955506"],
                    ["id": "5",
                     "patientName": "Patient Name  #09293283",
                     "description": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                     "doctorName": "Dr. Dave Loewen",
                     "date": "October 20 2017",
                     "photoURL": "https://s3-us-west-2.amazonaws.com/medic-image/radioish1507784695841"]
        ]
        
        searchedPatients = patients
        self.tvPatients.reloadData()
    }
    
    func loadSearchResult(_ keyword: String) {
        // Local search
        if keyword == "" {
            searchedPatients = patients
        } else {
            searchedPatients = patients.filter({(patient:[String: String]) -> Bool in
                return patient["patientName"]!.contains(keyword)
            })
        }
        
        self.tvPatients.reloadData()
    }
    
}

extension PatientsViewController : UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableView DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        return 1
    }
    
    func numberOfRows(inTableView: UITableView, section: Int) -> Int {
        return self.searchedPatients.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows(inTableView: tableView, section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PatientListCell = tableView.dequeueReusableCell(withIdentifier: PatientCellID) as! PatientListCell
        
        let data = self.searchedPatients[indexPath.row]
        cell.setData(data: data)
        
//        cell.btnAction.addTarget(self, action: #selector(onToggleAction(sender:)), for: .touchUpInside)
//        cell.btnAction.index = indexPath.row
//        cell.btnAction.refTableView = tableView
        cell.btnAction.isHidden = true
        
//        let tapGestureOnUserAvatar = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
//        cell.imgUserPhoto.addGestureRecognizer(tapGestureOnUserAvatar)
//        cell.imgUserPhoto.tag = indexPath.row
//
//        let tapGestureOnUsername = UITapGestureRecognizer(target: self, action: #selector(onSelectUser(sender:)))
//        cell.lblDoctorName.addGestureRecognizer(tapGestureOnUsername)
//        cell.lblDoctorName.tag = indexPath.row
        
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
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let _patient = self.patients[indexPath.row] as [String: String]? else {
            return
        }
        
        let patientProfileVC = self.storyboard!.instantiateViewController(withIdentifier: "PatientProfileViewController") as! PatientProfileViewController
        patientProfileVC.patient = _patient
        self.navigationController?.pushViewController(patientProfileVC, animated: true)

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
            
            let patient = searchedPatients[indexPath.row]
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
            
            let patient = searchedPatients[indexPath.row]
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
        self.performSegue(withIdentifier: Constants.SegueMedicConnectAddPatient, sender: nil)
    }
    
}

extension PatientsViewController : UITextFieldDelegate {
    // UITextfield delegate methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var txtAfterUpdate: NSString =  NSString(string: self.txFieldSearch.text!)
        txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
        txtAfterUpdate = txtAfterUpdate.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        
        // Remote search
//        if txtAfterUpdate.length > 0 {
//            self.searchTimer?.invalidate()
//            self.searchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(SearchViewController.loadData(searchTimer:)), userInfo: txtAfterUpdate as String, repeats: false)
//        }
        
        self.loadSearchResult(txtAfterUpdate as String)
        
        return true
    }
    
}
