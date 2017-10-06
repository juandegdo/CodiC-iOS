//
//  WelcomeViewController.swift
//  MedicConnect
//
//  Created by alessandro on 2/23/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import TwitterKit
import FacebookCore
import FacebookLogin

class WelcomeViewController: BaseViewController {
    
    @IBOutlet var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
    }
    
    // MARK: Initialize Views
    
    func initViews() {
        
        // Page Control
        self.pageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
    }
    
    func callWelcomeProfileVC() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "WelcomeProfileVC") as? WelcomeProfileViewController {
            self.navigationController?.pushViewController(vc, animated: false)
        }
        
    }
    
    @IBAction func tapSignup(_ sender: Any) {
        
        self.performSegue(withIdentifier: Constants.SegueMedicConnectSignup, sender: nil)
        
    }
    
    @IBAction func onTwitter(_ sender: UIButton) {
        sender.isEnabled = false
        Twitter.sharedInstance().logIn(completion: { (session, error) in
            if let s = session {
                print("logged in user with id \(s.userID)")
                print("logged in user with name \(s.userName)")
                
                let client = TWTRAPIClient.withCurrentUser()
                client.loadUser(withID: s.userID, completion: { (user, error) in
                    if let u = user {
                        print("logged in user with screen name \(u.name)" )
                        
                        client.requestEmail { email, error in
                            if (email != nil) {
                                print("logged in user with name \(email!)")
                                
                                let password = u.screenName + u.userID
                                let _user = User(fullName: u.name, email: email!, password: password)
                                
                                UserService.Instance.signup(_user, completion: {
                                    (success: Bool, message: String) in
                                    
                                    if success {
                                        // Set FirstLoad to 0 to show tutorials for new users
                                        UserDefaultsUtil.SaveFirstLoad(firstLoad: 0)
                                        
                                        self.callWelcomeProfileVC()
                                    } else {
                                        if !message.isEmpty {
                                            AlertUtil.showOKAlert(self, message: message)
                                        }
                                        
                                    }
                                    
                                    sender.isEnabled = true
                                })
                            }
                        }
                    }
                })
                
            } else {
                // log error
                if let e = error {
                    print("error: \(e.localizedDescription)")
                }
                sender.isEnabled = true
            }
        })
    }
    
    @IBAction func onFacebook(_ sender: UIButton) {
        sender.isEnabled = false
        
        let loginManager = LoginManager()
        loginManager.logIn([ .publicProfile, .email, .userFriends ], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success( _, _, let accessToken):
                print("Logged in!")
                let request = GraphRequest(graphPath: "me", parameters: ["fields": "email, name"], accessToken: accessToken, httpMethod: .GET, apiVersion: FacebookCore.GraphAPIVersion.defaultVersion)
                request.start { (response, result) in
                    switch result {
                    case .success(let value):
                        if let fbUser = value.dictionaryValue, let fullName = fbUser["name"] as? String, let email = fbUser["email"] as? String, let id = fbUser["id"] as? String {
                            print(fbUser)
                            
                            let password = fullName + id
                            let _user = User(fullName: fullName, email: email, password: password)
                            
                            UserService.Instance.signup(_user, completion: {
                                (success: Bool, message: String) in
                                
                                if success {
                                    // Set FirstLoad to 0 to show tutorials for new users
                                    UserDefaultsUtil.SaveFirstLoad(firstLoad: 0)
                                    
                                    self.callWelcomeProfileVC()
                                } else {
                                    if !message.isEmpty {
                                        AlertUtil.showOKAlert(self, message: message)
                                    }
                                    
                                }
                                
                                sender.isEnabled = true
                            })
                        }
                        else {
                            sender.isEnabled = true
                            AlertUtil.showOKAlert(self, message: "Oops! Failed to fetch user information from Facebook.")
                        }
                        
                        break
                    case .failed(let error):
                        print(error)
                        sender.isEnabled = true
                        AlertUtil.showOKAlert(self, message: "Oops! Failed to authenticate Facebook.")
                    }
                }
            }
        }
    }
}
