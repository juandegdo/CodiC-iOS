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
        
        self.tfDoctorMSPNumber.leftView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
        self.tfDoctorMSPNumber.leftViewMode = .always
        
    }
    
    // MARK: Private Methods
    
    func presentCreatePatient(_ patientNumber: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "CreatePatientViewController") as? CreatePatientViewController {
            vc.fromRecord = true
            vc.patientNumber = patientNumber
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func presentRecordScreen(_ patientId: String, _ userId: String ) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
            
            DataManager.Instance.setPostType(postType: Constants.PostTypeNote)
            DataManager.Instance.setPatientId(patientId: patientId)
            DataManager.Instance.setReferringUserId(referringUserId: userId)
            
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
        } else if (textField == self.tfDoctorMSPNumber) { /// phone number
            return newLength <= Constants.MaxMSPLength
        }
        
        return true
        
    }
}

extension ConsultReferringViewController {
    
    //MARK: IBActions
    
    @IBAction func onBack(sender: UIButton!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _nav.popToRootViewController(animated: true)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onCreatePatient(sender: UIButton!) {
        self.presentCreatePatient("")
    }
    
    @IBAction func onRecordConsult(sender: UIButton!) {
        // Go to Record screen
        if self.tfPatientNumber.text?.count == 0 {
            self.presentCreatePatient("")
            return
        }
        
        PatientService.Instance.getPatientIdByPHN(PHN: self.tfPatientNumber.text!) { (success, patientId) in
            
            if success == true {
                if patientId == nil || patientId == "" {
                    // Not found
                    DispatchQueue.main.async {
                        self.presentCreatePatient(self.tfPatientNumber.text!)
                    }
                    
                } else {
                    // Found
                    if self.tfDoctorMSPNumber.text?.count == 0 {
                        DispatchQueue.main.async {
                            self.presentRecordScreen(patientId!, "")
                        }
                    } else {
                        // Check if MSP number exists
                        UserService.Instance.getUserIdByMSP(MSP: self.tfDoctorMSPNumber.text!) { (success, userId) in
                            
                            if success == true {
                                // Show recording screen
                                DispatchQueue.main.async {
                                    self.presentRecordScreen(patientId!, userId!)
                                }
                            }
                        }
                    }
                }
            }
        }
        
    }
}
