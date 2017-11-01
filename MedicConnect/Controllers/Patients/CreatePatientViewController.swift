//
//  CreatePatientViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-31.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import ACFloatingTextfield

class CreatePatientViewController: BaseViewController {
    
    @IBOutlet var tfName: ACFloatingTextField!
    @IBOutlet var tfPHN: ACFloatingTextField!
    @IBOutlet var tfBirthdate: ACFloatingTextField!
    @IBOutlet var tfPhoneNumber: ACFloatingTextField!
    @IBOutlet var tfAddress: ACFloatingTextField!
    @IBOutlet var btnSave: UIButton!
    
    var alertWindow: UIWindow!
    
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
        
        // Birthdate
        self.tfBirthdate.placeholder = NSLocalizedString("Birthdate", comment: "comment")
        
        // Phone Number
        self.tfPhoneNumber.placeholder = NSLocalizedString("Phone #", comment: "comment")
        
        // Address
        self.tfAddress.placeholder = NSLocalizedString("Address", comment: "comment")
        
        // Save Button
//        self.btnSave.layer.cornerRadius = 3
//        self.btnSave.clipsToBounds = true
//        self.btnSave.layer.borderColor = UIColor.init(red: 255/255.0, green: 13/255.0, blue: 13/255.0, alpha: 1.0).cgColor
//        self.btnSave.layer.borderWidth = 1
//        self.btnSave.setBackgroundColor(color: UIColor.init(white: 0.5, alpha: 1.0), forState: .highlighted)
        
    }
    
}

extension CreatePatientViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        
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
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func onSaveChange(sender: AnyObject!) {
        self.onBack(sender: nil)
    }
    
}
