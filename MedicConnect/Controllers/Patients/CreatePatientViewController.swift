//
//  CreatePatientViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-31.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import ACFloatingTextfield_Swift

class CreatePatientViewController: BaseViewController {
    
    @IBOutlet var tfName: ACFloatingTextfield!
    @IBOutlet var tfPHN: ACFloatingTextfield!
    @IBOutlet var tfBirthdate: ACFloatingTextfield!
    @IBOutlet var tfPhoneNumber: ACFloatingTextfield!
    @IBOutlet var tfAddress: ACFloatingTextfield!
    @IBOutlet var btnSave: UIButton!
    
    var alertWindow: UIWindow!
    var birthDate: Date!
    var fromRecord: Bool = false
    var patientNumber: String = ""
    var isSaved: Bool = false
    
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
        
    }
    
    // MARK: Initialize Views
    
    func initViews() {
        // Name
        self.tfName.placeholder = NSLocalizedString("Name", comment: "comment")
        
        // PHN
        self.tfPHN.placeholder = NSLocalizedString("PHN#", comment: "comment")
        self.tfPHN.text = self.patientNumber
        
        // Birthdate
        self.tfBirthdate.placeholder = NSLocalizedString("Birthdate", comment: "comment")
        
        let datePickerView:UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.addTarget(self, action: #selector(CreatePatientViewController.datePickerValueChanged), for:.valueChanged)
        self.tfBirthdate.inputView = datePickerView
        
        // Phone Number
        self.tfPhoneNumber.placeholder = NSLocalizedString("Phone #", comment: "comment")
        
        // Address
        self.tfAddress.placeholder = NSLocalizedString("Address", comment: "comment")
        
    }
    
}

extension CreatePatientViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        if (textField == self.tfName) {
            return newLength <= Constants.MaxFullNameLength
        } else if (textField == self.tfPhoneNumber) { /// phone number
            return newLength <= Constants.MaxPhoneNumberLength
        }
        
        return true
    }
}

extension CreatePatientViewController {
    
    // MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject!) {
        if let _nav = self.navigationController as UINavigationController? {
            if self.fromRecord == true && isSaved == true {
                _nav.popToRootViewController(animated: false)
            } else {
                _nav.popViewController(animated: false)
            }
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func onSaveChange(sender: AnyObject!) {
        guard  self.tfName.text?.count != 0 else {
            AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to give your patient name!")
            return
        }
        
        guard  self.tfPHN.text?.count != 0 else {
            AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to give your patient number!")
            return
        }
        
        guard  self.tfBirthdate.text?.count != 0 else {
            AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to give your patient birthdate!")
            return
        }
        
        guard  self.tfPhoneNumber.text?.count != 0 else {
            AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to give your patient phone number!")
            return
        }
        
        guard  self.tfAddress.text?.count != 0 else {
            AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to give your patient address!")
            return
        }
        
        PatientService.Instance.addPatient(self.tfName.text!, patientNumber: self.tfPHN.text!, birthDate: self.birthDate, phoneNumber: self.tfPhoneNumber.text!, address: self.tfAddress.text!) { (success: Bool, patient: Patient?) in
            
            if patient != nil {
                self.isSaved = true
                
                DispatchQueue.main.async {
                    if self.fromRecord == true {
                        // Go to record screen
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        
                        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
                            
                            DataManager.Instance.setPostType(postType: Constants.PostTypeNote)
                            DataManager.Instance.setPatientId(patientId: (patient?.id)!)
                            DataManager.Instance.setReferringUserId(referringUserId: "")
                            
                            weak var weakSelf = self
                            self.present(vc, animated: false, completion: {
                                weakSelf?.onBack(sender: nil)
                            })
                            
                        }
                        
                    } else {
                        // Go to patient profile
                        let patientProfileVC = self.storyboard!.instantiateViewController(withIdentifier: "PatientProfileViewController") as! PatientProfileViewController
                        patientProfileVC.patient = patient
                        patientProfileVC.fromAdd = true
                        self.navigationController?.pushViewController(patientProfileVC, animated: false)
                    }
                }
            }
            
        }
        
    }
    
    @IBAction func datePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        self.birthDate = sender.date
        self.tfBirthdate.text = dateFormatter.string(from: sender.date)
        
    }
    
}
