//
//  SettingListCell.swift
//  Radioish
//
//  Created by alessandro on 12/22/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import TwitterKit
import FacebookCore

protocol SettingListCellDelegate {
    func switchValueChanged(sender: UISwitch, indexPath: IndexPath)
}

class SettingListCell: UITableViewCell {
    
    let DefaultLabelLeading = 25.0
    
    @IBOutlet var imgSocial: UIImageView!
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var switchCtrl: UISwitch!
    @IBOutlet var imgArrow: UIImageView!
    @IBOutlet var titleLeadingConstraint: NSLayoutConstraint!
    
    var indexPath : IndexPath?
    var delegate : SettingListCellDelegate?
    
    func setCellWithTitle(title: String, iconImage: UIImage!, hasSwitch: Bool, hasArrow: Bool, tag: IndexPath = IndexPath(row: 0, section: 0)) {
        
        self.selectionStyle = UITableViewCellSelectionStyle.default
        
        self.imgSocial.isHidden = true
        self.switchCtrl.isHidden = true
        self.switchCtrl.isOn = false
        self.imgArrow.isHidden = true
        self.titleLeadingConstraint.constant = CGFloat(DefaultLabelLeading)
        
        self.lblTitle.text = title
        
        if let _image = iconImage as UIImage? {
            
            self.imgSocial.isHidden = false
            self.imgSocial.image = _image
            self.titleLeadingConstraint.constant = CGFloat(DefaultLabelLeading) + 50.0
            
        }
        
        
        if hasArrow {
            
            self.imgArrow.isHidden = false
            
        }
        
        if hasSwitch {
            self.switchCtrl.isHidden = false
            self.switchCtrl.isOn = false
            
            if (tag.section == 0 && tag.row == 3){
                self.switchCtrl.isOn = UserController.Instance.getUser().isprivate
                return
            }
            else if tag.section == 1 {
                //            self.switchCtrl.tag = tag
                //            self.switchCtrl.isHidden = false
                self.selectionStyle = UITableViewCellSelectionStyle.none
                if NotificationUtil.isEnabledPushNotification() {
                    if let _me = UserController.Instance.getUser() {
                        self.switchCtrl.isOn = ((_me.notificationfilter & (1<<tag.row)) != 0) //(_me.deviceToken != nil)
                        return
                    }
                }
            }
            else if tag.section == 3 {
                if tag.row == 0 {
                    let store = Twitter.sharedInstance().sessionStore
                    if let _ = store.session()?.userID {
                        self.switchCtrl.isOn = true
                    }
                }
                else if tag.row == 1 {
                    if let _ = AccessToken.current {
                        self.switchCtrl.isOn = true
                    }
                }
            }
        }
        
    }
    
    @IBAction func swValueChanged(_ sender: Any) {
        let sw = sender as! UISwitch
        if (indexPath?.section == 0 && indexPath?.row == 3){
            
        } else if indexPath?.section == 1 {
            if sw.isOn {
                if NotificationUtil.isEnabledPushNotification() {
                    
                } else {
                    sw.isOn = false
                    NotificationUtil.processPushNotificationSettings()
                }
            }
        }
        
        if let del = delegate, let idxPath = indexPath {
            del.switchValueChanged(sender: sw, indexPath: idxPath)
        }
//        NotificationUtil.makeUserNotificationEnabled()
//        if let _me = UserController.Instance.getUser(),
//            (_me.deviceToken == nil && value == true) {
//            NotificationUtil.makeUserNotificationEnabled()
//        } else {
//            
//        }
        
    }
}
