//
//  SplashViewController.swift
//  Radioish
//
//  Created by Daniel Yang on 2017-08-11.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.checkUser()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func checkUser() {
        
        if !UserDefaultsUtil.LoadToken().isEmpty {
            
            UserService.Instance.getMe(completion: {
                (user: User?) in
                if let _user = user as User? {
                    // User logged in
                    UserController.Instance.setUser(_user)
                    self.performSegue(withIdentifier: Constants.SegueRadioishHome, sender: nil)
                } else {
                    // User not logged in properly
                    self.performSegue(withIdentifier: Constants.SegueRadioishSignIn, sender: nil)
                }
            })
            
        } else {
            // User not logged in
            self.performSegue(withIdentifier: Constants.SegueRadioishSignIn, sender: nil)
        }
        
    }

}
