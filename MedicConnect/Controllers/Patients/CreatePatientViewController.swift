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
    
    @IBOutlet var lblTitle: UILabel!
    
    @IBOutlet var tfName: ACFloatingTextfield!
    @IBOutlet var tfPHN: ACFloatingTextfield!
    @IBOutlet var tfBirthdate: ACFloatingTextfield!
    @IBOutlet var tfPhoneNumber: ACFloatingTextfield!
    @IBOutlet var tfAddress: ACFloatingTextfield!
    @IBOutlet var lblPHNError: UILabel!
    @IBOutlet var btnSave: UIButton!
    
    var birthDate: Date!
    var fromRecord: Bool = false
    var patientNumber: String = ""
    var isSaved: Bool = false
    
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
        
    }
    
    // MARK: Initialize Views
    
    func initViews() {
        // Name
        self.tfName.placeholder = NSLocalizedString("Name", comment: "comment")
        
        // PHN
        self.tfPHN.placeholder = NSLocalizedString("PHN#", comment: "comment")
        self.tfPHN.text = self.patientNumber
        self.tfPHN.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        self.lblPHNError.isHidden = true
        
        // Birthdate
        self.tfBirthdate.placeholder = NSLocalizedString("Birthdate", comment: "comment")
        
        let datePickerView:UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.addTarget(self, action: #selector(CreatePatientViewController.datePickerValueChanged), for:.valueChanged)
        self.tfBirthdate.inputView = datePickerView
        
        // Phone Number
        self.tfPhoneNumber.placeholder = NSLocalizedString("Phone # (optional)", comment: "comment")
        self.tfPhoneNumber.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Address
        self.tfAddress.placeholder = NSLocalizedString("Address (optional)", comment: "comment")
        
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
        } else if (textField == self.tfPHN) {
            return newLength <= Constants.MaxPHNLength
        }
        
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == self.tfPhoneNumber {
            // Format phone number
            textField.text = StringUtil.formatPhoneNumber(numberString: textField.text!)
            
        } else {
            // When the user performs a repeating action, such as entering text, invoke the `call` method
            debouncer.call()
            debouncer.callback = {
                // Send the debounced network request here
                if (textField == self.tfPHN && textField.text!.count > 0) {
                    // Check if patient exists
                    self.btnSave.isUserInteractionEnabled = false
                    PatientService.Instance.getPatientIdByPHN(PHN: self.tfPHN.text!) { (success, PHN, patientId, patientName) in
                        self.btnSave.isUserInteractionEnabled = true
                        
                        if success == true && PHN == self.tfPHN.text! {
                            if patientId == nil || patientId == "" {
                                self.lblPHNError.isHidden = true
                            } else {
                                self.lblPHNError.isHidden = false
                            }
                        } else if success == false {
                            self.lblPHNError.isHidden = true
                        }
                    }
                }
            }
        }
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
            AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to give your patient name!", message: nil, okButtonTitle: "OK")
            return
        }
        
        guard  self.tfPHN.text?.count != 0 else {
            AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to give your patient number!", message: nil, okButtonTitle: "OK")
            return
        }
        
        if !self.lblPHNError.isHidden {
            return
        }
        
        guard  self.tfBirthdate.text?.count != 0 else {
            AlertUtil.showSimpleAlert(self, title: "Oops, it looks like you forgot to give your patient birthdate!", message: nil, okButtonTitle: "OK")
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
                            DataManager.Instance.setReferringUserIds(referringUserIds: [])
                            DataManager.Instance.setFromPatientProfile(false)
                            
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
