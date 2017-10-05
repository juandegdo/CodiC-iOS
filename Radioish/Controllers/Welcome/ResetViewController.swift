//
//  ResetViewController.swift
//  Radioish
//
//  Created by Alessandro Zoffoli on 27/02/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import ACFloatingTextfield

class ResetViewController: BaseViewController {
    
    @IBOutlet var txFieldEmail: ACFloatingTextField!
    @IBOutlet var btnSend: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Email
        self.txFieldEmail.placeholder = NSLocalizedString("Email", comment: "comment")
    }
    
    //MARK: - UI Actions
    @IBAction func resetPassword() {
        
        if let email = self.txFieldEmail.text as String? {
            
            if email.isEmpty {
                AlertUtil.showOKAlert(self, message: "Please enter email address.")
                return
            }
            if !StringUtil.isValidEmail(email) {
                AlertUtil.showOKAlert(self, message: "Please enter valid email address.")
                return
            }
            
            self.btnSend.isEnabled = false
            
            let token = StringUtil.randomString(length: 12)
            
            UserService.Instance.forgotPassword(email: email, token: token, completion: {
                (success: Bool, code: Int?) in
                
                self.btnSend.isEnabled = true
                
                if success {
                    AlertUtil.showOKAlert(self, message: "Okay, check your mail. We sent you a link to reset your password.", okCompletionBlock: {
                        UserDefaultsUtil.SaveForgotPasswordToken(token: token)
                        _ = self.navigationController?.popViewController(animated: false)
                    })
                }
                else {
                    if code == 404 {
                        AlertUtil.showOKAlert(self, message: "Looks like we don't have that email address on file.")
                    }
                    else {
                        AlertUtil.showOKAlert(self, message: "Something went wrong on server. Please contact administrator.")
                    }
                }
                
            })
        }
        
    }
    
    @IBAction func dismiss() {
        
        _ = self.navigationController?.popViewController(animated: false)
        
    }
}
