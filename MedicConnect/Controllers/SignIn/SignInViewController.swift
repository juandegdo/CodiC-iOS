//
//  SignInViewController.swift
//  MedicConnect
//
//  Created by alessandro on 11/21/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import ACFloatingTextfield

class SignInViewController: BaseViewController, UITextFieldDelegate {
    
    @IBOutlet var tfEmail: ACFloatingTextField!
    @IBOutlet var tfPassword: ACFloatingTextField!
    @IBOutlet var btnSignin: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
        let notificationName = NSNotification.Name(rawValue:"goToResetPassword")
        NotificationCenter.default.addObserver(self, selector: #selector(openResetPassword(_:)), name: notificationName, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.endEditing(true)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.tfEmail.text = ""
        self.tfPassword.text = ""
        self.view.endEditing(true)
        
    }
    
    //MARK: - Notification Observer
    @objc func openResetPassword(_ notification: NSNotification) {
        if let token = notification.userInfo?["token"] as? String, let tokenOnDevice = UserDefaultsUtil.LoadForgotPasswordToken(), token == tokenOnDevice{
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResetPasswordVC") as! ResetPasswordViewController
            vc.token = token
            self.navigationController?.pushViewController(vc, animated: false)
        }
        else {
            AlertUtil.showOKAlert(self, message: "Link is not valid.")
        }
    }
    
    // MARK: Private methods
    
    func initViews() {
    
        // Email
        self.tfEmail.placeholder = NSLocalizedString("Email", comment: "comment")
        if !UserDefaultsUtil.LoadUserName().isEmpty {
            self.tfEmail.text = UserDefaultsUtil.LoadUserName()
        }
        
        // Pasword
        self.tfPassword.placeholder = NSLocalizedString("Password", comment: "comment")
        if !UserDefaultsUtil.LoadPassword().isEmpty {
            self.tfPassword.text = UserDefaultsUtil.LoadPassword()
        }
        
    }
    
}

extension SignInViewController {

    // MARK: IBActions
    
    @IBAction func onLogin(sender: AnyObject) {
        
        // Check if all required fields are filled
        if self.tfEmail.text!.isEmpty || self.tfPassword.text!.isEmpty {
            AlertUtil.showOKAlert(self, message: "Please fill in all fields")
            return
        }
        
        // Check if email is valid
        if !StringUtil.isValidEmail(self.tfEmail.text!) {
            AlertUtil.showOKAlert(self, message: "Please enter a valid email address")
            return
        }
        
        self.view.endEditing(true)
        
        let _user = User(email: self.tfEmail.text!, password: self.tfPassword.text!)
        
        UserDefaultsUtil.SaveUserName(username: _user.email)
        UserDefaultsUtil.SavePassword(password: _user.password)
        
        self.btnSignin.isEnabled = false
        UserService.Instance.login(_user, completion: {
            (success: Bool, message: String) in
            
            if success {
                self.navigationController?.popViewController(animated: false)
                
            } else {
                if !message.isEmpty {
                    AlertUtil.showOKAlert(self, message: message)
                }
                
            }
            self.btnSignin.isEnabled = true
            
        })  
    }
    
    @IBAction func tapSignup(_ sender: Any) {
        self.view.endEditing(true)
        self.performSegue(withIdentifier: Constants.SegueMedicConnectSignup, sender: nil)
    }
    
    @IBAction func onResetPassword(sender: AnyObject) {
        self.view.endEditing(true)
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResetVC")
        self.navigationController?.pushViewController(vc, animated: false)
        
    }
}
