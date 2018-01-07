//
//  ConsultReferringViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-12-14.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class ConsultReferringViewController: UIViewController {

    @IBOutlet weak var tfPatientNumber: UITextField!
    @IBOutlet weak var tfDoctorMSPNumber: UITextField!
    
    @IBOutlet weak var lblPHNError: UILabel!
    @IBOutlet weak var lblMSPError: UILabel!
    
    @IBOutlet weak var btnRecord: UIButton!
    
    var patientID: String = ""
    var referUserID: String = ""
    
    let debouncer = Debouncer(interval: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Initialize views
    
    func initViews() {
        self.tfPatientNumber.delegate = self
        self.tfDoctorMSPNumber.delegate = self
        
        self.tfPatientNumber.leftView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
        self.tfPatientNumber.leftViewMode = .always
        self.tfPatientNumber.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        self.tfDoctorMSPNumber.leftView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
        self.tfDoctorMSPNumber.leftViewMode = .always
        self.tfDoctorMSPNumber.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Hide error labels
        self.lblPHNError.isHidden = true
        self.lblMSPError.isHidden = true
        
        // Add checkmarks on right views
        for textField in [self.tfPatientNumber, self.tfDoctorMSPNumber] {
            let ivCheck: UIImageView = UIImageView.init(frame: CGRect.init(x: 8, y: 16.5, width: 11, height: 11))
            ivCheck.image = UIImage.init(named: "icon_save_done_new")
            let view: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 27, height: 44))
            view.addSubview(ivCheck)
            
            textField?.rightView = view
            textField?.rightViewMode = .always
        }
        
        // Hide checkmarks
        self.tfPatientNumber.rightView?.isHidden = true
        self.tfDoctorMSPNumber.rightView?.isHidden = true
        
    }
    
    // MARK: Private Methods
    
    func presentCreatePatient(_ patientNumber: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "CreatePatientViewController") as? CreatePatientViewController {
            vc.fromRecord = true
            vc.patientNumber = patientNumber
            
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    func presentErrorPopup(_ popupType: ErrorPopupType) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "ErrorPopupViewController") as? ErrorPopupViewController {
            vc.popupType = popupType
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    func presentRecordScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
            
            DataManager.Instance.setPostType(postType: Constants.PostTypeNote)
            DataManager.Instance.setPatientId(patientId: patientID)
            DataManager.Instance.setReferringUserIds(referringUserIds: [referUserID])
            DataManager.Instance.setFromPatientProfile(false)
            
            weak var weakSelf = self
            self.present(vc, animated: false, completion: {
                weakSelf?.onBack(sender: nil)
            })
            
        }
    }

}

extension ConsultReferringViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        if (textField == self.tfPatientNumber) {
            return newLength <= Constants.MaxPHNLength
        } else if (textField == self.tfDoctorMSPNumber) {
            return newLength <= Constants.MaxMSPLength
        }
        
        return true
        
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        // When the user performs a repeating action, such as entering text, invoke the `call` method
        textField.textColor = UIColor.black
        textField.rightView?.isHidden = true
        
        debouncer.call()
        debouncer.callback = {
            // Send the debounced network request here
            if (textField.text!.count > 0) {
                if (textField == self.tfPatientNumber) {
                    // Check if patient exists
                    self.btnRecord.isUserInteractionEnabled = false
                    PatientService.Instance.getPatientIdByPHN(PHN: self.tfPatientNumber.text!) { (success, PHN, patientId) in
                        self.btnRecord.isUserInteractionEnabled = true
                        
                        if success == true && PHN == self.tfPatientNumber.text! {
                            if patientId == nil || patientId == "" {
                                self.lblPHNError.isHidden = false
                                self.tfPatientNumber.textColor = UIColor.red
                            } else {
                                self.patientID = patientId!
                                self.lblPHNError.isHidden = true
                                self.tfPatientNumber.textColor = UIColor.black
                            }
                        } else if success == false {
                            self.lblPHNError.isHidden = false
                            self.tfPatientNumber.textColor = UIColor.red
                        }
                        
                        self.tfPatientNumber.rightView?.isHidden = !self.lblPHNError.isHidden
                    }
                } else if (textField == self.tfDoctorMSPNumber) {
                    // Check if MSP number exists
                    self.btnRecord.isEnabled = false
                    UserService.Instance.getUserIdByMSP(MSP: self.tfDoctorMSPNumber.text!) { (success, MSP, userId) in
                        self.btnRecord.isEnabled = true
                        
                        if success == true && MSP == self.tfDoctorMSPNumber.text! {
                            if userId == nil || userId == "" {
                                self.lblMSPError.isHidden = false
                                self.tfDoctorMSPNumber.textColor = UIColor.red
                            } else {
                                self.referUserID = userId!
                                self.lblMSPError.isHidden = true
                                self.tfDoctorMSPNumber.textColor = UIColor.black
                            }
                        } else if success == false {
                            self.lblMSPError.isHidden = false
                            self.tfDoctorMSPNumber.textColor = UIColor.red
                        }
                        
                        self.tfDoctorMSPNumber.rightView?.isHidden = !self.lblMSPError.isHidden
                    }
                }
            }
        }
    }
}

extension ConsultReferringViewController {
    
    //MARK: IBActions
    
    @IBAction func onBack(sender: UIButton!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _nav.popToRootViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onCreatePatient(sender: UIButton!) {
        self.presentCreatePatient("")
    }
    
    @IBAction func onRecordConsult(sender: UIButton!) {
        // Go to Record screen
        var errorType: ErrorPopupType = .none
        if (self.tfPatientNumber.text!.count == 0 || !self.lblPHNError.isHidden) && (self.tfDoctorMSPNumber.text!.count == 0 || !self.lblMSPError.isHidden) {
            errorType = .noMSPAndPHN
            DataManager.Instance.setPostType(postType: Constants.PostTypeConsult)
            DataManager.Instance.setPatientId(patientId: "")
            DataManager.Instance.setReferringUserIds(referringUserIds: [""])
            
        } else if (self.tfPatientNumber.text!.count == 0 || !self.lblPHNError.isHidden) {
            errorType = .noPHN
            DataManager.Instance.setPostType(postType: Constants.PostTypeNote)
            DataManager.Instance.setPatientId(patientId: "")
            DataManager.Instance.setReferringUserIds(referringUserIds: [self.referUserID])
            
        } else if (self.tfDoctorMSPNumber.text!.count == 0 || !self.lblMSPError.isHidden) {
            errorType = .noMSP
            DataManager.Instance.setPostType(postType: Constants.PostTypeNote)
            DataManager.Instance.setPatientId(patientId: self.patientID)
            DataManager.Instance.setReferringUserIds(referringUserIds: [""])
            
        }
        
        if (errorType != .none) {
            // Show Error Popup
            self.presentErrorPopup(errorType)
            return
        }
        
        // Show record screen
        self.presentRecordScreen()
        
    }
    
    @IBAction func onSkip(sender: UIButton!) {
        // Skip
        DataManager.Instance.setPostType(postType: Constants.PostTypeConsult)
        DataManager.Instance.setPatientId(patientId: "")
        DataManager.Instance.setReferringUserIds(referringUserIds: [""])
        
        // Show record screen
        self.presentRecordScreen()
    }
    
}
