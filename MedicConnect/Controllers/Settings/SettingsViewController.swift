//
//  SettingsViewController.swift
//  MedicConnect
//
//  Created by alessandro on 12/22/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import MessageUI

class SettingsViewController: BaseViewController {
    
    let SettingsHeaderCellID = "SettingHeaderCell"
    let SettingsListCellID = "SettingListCell"
    
    @IBOutlet var tvSettings: UITableView!
    
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
    
    //MARK: Initialize Views
    
    func initViews() {
        
        // Initialize Table Views
        self.tvSettings.register(UINib(nibName: SettingsHeaderCellID, bundle: nil), forCellReuseIdentifier: SettingsHeaderCellID)
        self.tvSettings.register(UINib(nibName: SettingsListCellID, bundle: nil), forCellReuseIdentifier: SettingsListCellID)
        self.tvSettings.tableFooterView = UIView()
        
    }
    
}

extension SettingsViewController : UITableViewDataSource, UITableViewDelegate {
    
    //MARK: UITableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == self.tvSettings {
            return 3
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tvSettings {
            
            switch (section) {
            case 0:
                return 6
            case 1:
                return 3
            case 2:
                return 4
                
            default:
                break
            }
            
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tvSettings {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsListCellID) as! SettingListCell
            
            cell.delegate = self
            cell.indexPath = indexPath
            
            if indexPath.section == 0 {
                
                if indexPath.row == 0 {
                    cell.setCellWithTitle(title: NSLocalizedString("Edit Profile", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: true)
                }
                else if indexPath.row == 1 {
                    cell.setCellWithTitle(title: NSLocalizedString("Change Password", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: true)
                }
                else if indexPath.row == 2 {
                    cell.setCellWithTitle(title: NSLocalizedString("Blocked Users", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: true)
                }
                else if indexPath.row == 3 {
                    cell.setCellWithTitle(title: NSLocalizedString("Reset Tutorial", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: false)
                }
                else if indexPath.row == 4 {
                    cell.setCellWithTitle(title: NSLocalizedString("Logout", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: false)
                }
                else if indexPath.row == 5 {
                    cell.setCellWithTitle(title: NSLocalizedString("Delete Account", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: false)
                }
                
            } else if indexPath.section == 1 {
                
                if (indexPath.row == 0) {
                    cell.setCellWithTitle(title: NSLocalizedString("Likes", comment: "comment"), iconImage: nil, hasSwitch: true, hasArrow: false, tag: indexPath)
                }
                else if (indexPath.row == 1) {
                    cell.setCellWithTitle(title: NSLocalizedString("Comments", comment: "comment"), iconImage: nil, hasSwitch: true, hasArrow: false, tag: indexPath)
                }
                else if (indexPath.row == 2) {
                    cell.setCellWithTitle(title: NSLocalizedString("New Diagnosis", comment: "comment"), iconImage: nil, hasSwitch: true, hasArrow: false, tag: indexPath)
                }
                
            } else if indexPath.section == 2 {
                
                if (indexPath.row == 0) {
                    cell.setCellWithTitle(title: NSLocalizedString("About", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: true)
                }
                else if (indexPath.row == 1) {
                    cell.setCellWithTitle(title: NSLocalizedString("Privacy Policy", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: true)
                }
                else if (indexPath.row == 2) {
                    cell.setCellWithTitle(title: NSLocalizedString("Terms of Use", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: true)
                }else if (indexPath.row == 3) {
                    cell.setCellWithTitle(title: NSLocalizedString("Contact Us", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: true)
                }
                
            } else if indexPath.section == 3 {
                
                if (indexPath.row == 0) {
                    cell.setCellWithTitle(title: NSLocalizedString("Twitter Account", comment: "comment"), iconImage: nil, hasSwitch: true, hasArrow: false, tag: indexPath)
                }
                else if (indexPath.row == 1) {
                    cell.setCellWithTitle(title: NSLocalizedString("Facebook Account", comment: "comment"), iconImage: nil, hasSwitch: true, hasArrow: false, tag: indexPath)
                }
                else if (indexPath.row == 2) {
                    cell.setCellWithTitle(title: NSLocalizedString("Instagram Account", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: false)
                }
                else if (indexPath.row == 3) {
                    cell.setCellWithTitle(title: NSLocalizedString("Snapchat Account", comment: "comment"), iconImage: nil, hasSwitch: false, hasArrow: false)
                }
            }
            
            return cell
        }
        
        return UITableViewCell()
        
    }
    
    //MARK: UITableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.tvSettings {
            
            if indexPath.section == 0 { // Account
                
                if indexPath.row == 0 {
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let vc = storyboard.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController {
                        self.present(vc, animated: false, completion: nil)
                    }
                    
                } else if indexPath.row == 1 {
                    
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChangePasswordVC")
                    present(vc, animated: false, completion: nil)
                    
                } else if indexPath.row == 2 {
                    print("Blocked users")
                    
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BlockedUsersVCId")
                    present(vc, animated: false, completion: nil)
                    
                } else if indexPath.row == 3 {
                    print("Reset Tutorial")
                    
                    // Reset Tutorial
                    AlertUtil.showConfirmAlert(self, message: NSLocalizedString("Are you sure you want to reset tutorial?", comment: "comment"), okButtonTitle: NSLocalizedString("I'M SURE", comment: "comment"), cancelButtonTitle: NSLocalizedString("NEVER MIND", comment: "comment"), okCompletionBlock: {
                        // OK completion block
                        // Set FirstLoad to 0 to show tutorials for new users
                        UserDefaultsUtil.SaveFirstLoad(firstLoad: 0)
                        
                    }, cancelCompletionBlock: {
                        // Cancel completion block
                        
                    })
                    
                } else if indexPath.row == 4 {
                    
                    // Logout
                    AlertUtil.showConfirmAlert(self, message: NSLocalizedString("Are you sure you want to logout?", comment: "comment"), okButtonTitle: NSLocalizedString("I'M SURE", comment: "comment"), cancelButtonTitle: NSLocalizedString("NEVER MIND", comment: "comment"), okCompletionBlock: {
                        // OK completion block
                        self.clearAllData()
                        _ = self.tabBarController?.navigationController?.popToRootViewController(animated: true)
                        
                    }, cancelCompletionBlock: {
                        // Cancel completion block
                        
                    })
                    
                } else if indexPath.row == 5 {
                    
                    // Delete account
                    AlertUtil.showConfirmAlert(self, message: NSLocalizedString("Are you sure you want to delete your account?", comment: "comment"), okButtonTitle: NSLocalizedString("I'M SURE", comment: "comment"), cancelButtonTitle: NSLocalizedString("NEVER MIND", comment: "comment"), okCompletionBlock: {
                        // OK completion block
                        UserService.Instance.deleteAccount(completion: {
                            (success: Bool, message: String) in
                            
                            if success {
                                
                                self.clearAllData()
                                _ = self.tabBarController?.navigationController?.popToRootViewController(animated: true)
                                
                            } else {
                                if !message.isEmpty {
                                    AlertUtil.showOKAlert(self, message: message)
                                }
                            }
                        })
                        
                    }, cancelCompletionBlock: {
                        // Cancel completion block
                        
                    })
                    
                }
            } else if indexPath.section == 2 { // Information
                
                if (indexPath.row == 3) {
                    self.sendEmail(emailAddress: "info@radioishapp.com")
                    
                } else if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsDetailViewController") as? SettingsDetailViewController {
                    
                    if (indexPath.row == 0) {
                        vc.strTitle = "About"
                    } else if (indexPath.row == 1) {
                        vc.strTitle = "Privacy Policy"
                    }else if (indexPath.row == 2) {
                        vc.strTitle = "Terms of Use"
                    }
                    
                    present(vc, animated: false, completion: nil)
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
        
    }

    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerCell = tableView.dequeueReusableCell(withIdentifier: SettingsHeaderCellID) as! SettingHeaderCell
        
        if section == 0 {
            headerCell.setTitle(title: NSLocalizedString("Account", comment: "comment"))
        } else if section == 1 {
            headerCell.setTitle(title: NSLocalizedString("Notifications", comment: "comment"))
        } else if section == 2 {
            headerCell.setTitle(title: NSLocalizedString("Information", comment: "comment"))
        }
        
        return headerCell.contentView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if tableView == self.tvSettings {
            
            return 25.0
            
        }
        
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tvSettings {
            return 53.0
        }
        
        return 0.0
        
    }
    
}

extension SettingsViewController {
    
    //MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject) {
        
        self.dismissVC()
        
    }
    
}

extension SettingsViewController : MFMailComposeViewControllerDelegate {
    
    func sendEmail(emailAddress: String) {
        if !MFMailComposeViewController.canSendMail() {
            AlertUtil.showOKAlert(self, message: "Mail services are not available")
            return
        }
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients([emailAddress])
        composeVC.setSubject("Contact Us")
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController : SettingListCellDelegate {
    func switchValueChanged(sender: UISwitch, indexPath: IndexPath) {
        if (indexPath.section == 0 && indexPath.row == 3) {
            //private account was switched
            let value = sender.isOn
            makePrivate(value: value)
        } else {
            print("\n\(indexPath.section) : \(indexPath.row)\n")
            if (indexPath.section == 1) { // Notification Filter
                var tmpValue = UserController.Instance.getUser().notificationfilter
                if sender.isOn {
                    tmpValue = tmpValue | (1<<indexPath.row)
                } else {
                    tmpValue = tmpValue ^ (1<<indexPath.row)
                }
                print(tmpValue)
                
                UserService.Instance.setNotificationFilter(value: tmpValue, completion: { (success) in
                    UserService.Instance.getMe(completion: { (_) in
                        self.tvSettings.reloadSections(IndexSet.init(integer: 1), with: .none)
                    })
                    
                })
            }
        }
    }
    
    func makePrivate(value: Bool){
        
        UserService.Instance.makePrivate(value: value) { (success) in
            UserService.Instance.getMe(completion: { (_) in
                print("\ngot user\n")
            })
            print("\nMake Private: \(success) \n")
        }
    }
}
