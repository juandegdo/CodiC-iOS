//
//  SignUpViewController.swift
//  MedicConnect
//
//  Created by alessandro on 2/20/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import ACFloatingTextfield_Swift

class SignUpViewController: BaseViewController, UITextFieldDelegate {
    
    @IBOutlet var tfName: ACFloatingTextfield!
    @IBOutlet var tfEmail: ACFloatingTextfield!
    @IBOutlet var tfPassword: ACFloatingTextfield!
    @IBOutlet var tfConfirm: ACFloatingTextfield!
    @IBOutlet var btnSignup: UIButton!
    @IBOutlet var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
    }
    
    // MARK: Initialize Views
    
    func initViews() {
        
        // Name
        self.tfName.placeholder = NSLocalizedString("First & Last Name", comment: "comment")
        
        // Email
        self.tfEmail.placeholder = NSLocalizedString("Email", comment: "comment")
        
        // Pasword
        self.tfPassword.placeholder = NSLocalizedString("Password", comment: "comment")
        
        // Pasword
        self.tfConfirm.placeholder = NSLocalizedString("Confirm Password", comment: "comment")
        
        // Page Control
        self.pageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
    }
    
}

extension SignUpViewController {

    // MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func onSignUp(sender: AnyObject) {
        
        // Check if all required fields are filled
        if self.tfName.text!.isEmpty || self.tfPassword.text!.isEmpty || self.tfConfirm.text!.isEmpty || self.tfEmail.text!.isEmpty {
            AlertUtil.showOKAlert(self, message: "Please fill in all fields")
            return
        }
        
        // Check if email is valid
        if !StringUtil.isValidEmail(self.tfEmail.text!) {
            AlertUtil.showOKAlert(self, message: "Please enter a valid email address")
            return
        }
        
        // Check if passwords match
        if self.tfPassword.text! != self.tfConfirm.text! {
            AlertUtil.showOKAlert(self, message: "Yikes! The passwords you've entered don't match.")
            return
        }
        
        let _user = User(fullName: self.tfName.text!, email: self.tfEmail.text!, password: self.tfPassword.text!)
        
        self.btnSignup.isEnabled = false
        UserService.Instance.signup(_user, completion: {
            (success: Bool, message: String) in
            
            if success {
                // Set FirstLoad to 0 to show tutorials for new users
                UserDefaultsUtil.SaveFirstLoad(firstLoad: 0)
                
                self.performSegue(withIdentifier: Constants.SegueMedicConnectWelcomeProfile, sender: nil)
            } else {
                if !message.isEmpty {
                    AlertUtil.showOKAlert(self, message: message)
                }
                
            }
            
            self.btnSignup.isEnabled = true
            
        })
        
    }
    
    @IBAction func onLogin(sender: AnyObject) {
        
        self.onBack(sender: nil)
        
    }

}
