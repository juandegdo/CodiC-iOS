//
//  PatientsViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-16.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import IQKeyboardManager

class PatientsViewController: BaseViewController, UIGestureRecognizerDelegate, ExpandableLabelDelegate {
    
    let PatientCellID = "PatientListCell"
    
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var txFieldSearch: UITextField!
    @IBOutlet var tvPatients: UITableView!
    
    @IBOutlet var constOfTableViewBottom: NSLayoutConstraint!
    
    var vcDisappearType : ViewControllerDisappearType = .other
    var searchedPatients: [Patient] = []
    var selectedDotsIndex = 0
    var states = Set<String>()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        vcDisappearType = .other
//        IQKeyboardManager.shared().isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.loadPatients()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        IQKeyboardManager.shared().isEnabled = true
        NotificationCenter.default.removeObserver(self)
        
        if let tabvc = self.tabBarController as UITabBarController? {
            DataManager.Instance.setLastTabIndex(tabIndex: tabvc.selectedIndex)
        }
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

extension PatientsViewController {
    
    // MARK: Private methods
    
    func initViews() {
        // Initialize Table Views
        
        let nibPatientCell = UINib(nibName: PatientCellID, bundle: nil)
        self.tvPatients.register(nibPatientCell, forCellReuseIdentifier: PatientCellID)
        
        self.tvPatients.tableFooterView = UIView()
        self.tvPatients.estimatedRowHeight = 106.0
        self.tvPatients.rowHeight = UITableViewAutomaticDimension
        
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let bottomMargin = keyboardSize.height - 55.0
            constOfTableViewBottom.constant = bottomMargin
            
            UIView.animate(withDuration: 1, animations: {
                self.view.layoutIfNeeded()
            })
            
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        constOfTableViewBottom.constant = 0
        UIView.animate(withDuration: 1, animations: {
            self.view.layoutIfNeeded()
        })
        
//        isFirstKeyboardShow = false
    }
    
    func loadPatients() {
        // Load Patients
        
        PatientService.Instance.getPatients(completion: { (success: Bool) in
            self.loadSearchResult(self.txFieldSearch.text!)
        })
        
    }
    
    func loadSearchResult(_ keyword: String) {
        // Local search
        if keyword == "" {
            searchedPatients = []
        } else {
            searchedPatients = PatientController.Instance.getPatients().filter({(patient: Patient) -> Bool in
                return patient.patientNumber.contains(keyword)
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
        
        let patient = self.searchedPatients[indexPath.row]
        cell.setData(patient)
        
        cell.btnAction.isHidden = true
        
        let isFullDesc = self.states.contains(patient.id)
        cell.lblDescription.delegate = self
        cell.lblDescription.shouldCollapse = true
        cell.lblDescription.numberOfLines = isFullDesc ? 0 : 1;
        cell.lblDescription.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."
        cell.lblDescription.collapsed = !isFullDesc
        cell.showFullDescription = isFullDesc
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    // MARK: UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let _patient = self.searchedPatients[indexPath.row] as Patient? else {
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
            self.states.insert(patient.id)
            
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
            self.states.remove(patient.id)
            
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var txtAfterUpdate: NSString =  NSString(string: self.txFieldSearch.text!)
        txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
        txtAfterUpdate = txtAfterUpdate.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        
        self.loadSearchResult(txtAfterUpdate as String)
        
        return true
    }
    
}
