//
//  UserDefaultsUtil.swift
//  MedicConnect
//
//  Created by alessandro on 12/29/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit

class UserDefaultsUtil {

    class func SaveToken(_ token: String) {
        
        print("Save \(token)")
        
        UserService.Instance.configureInstance(token)
        
        KeychainService.savePassword(token: token as NSString)

    }
    
    class func LoadToken() -> String {
        return KeychainService.loadPassword() as String? ?? ""
    }
    
    class func DeleteToken() {
        UserService.Instance.configureInstance("")
        KeychainService.savePassword(token: "" as NSString)
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "password")
        
    }
    
    class func SaveUserId(userid: String) {
        let defaults = UserDefaults.standard
        defaults.set(userid, forKey: "userid")
        defaults.synchronize()
    }
    
    class func LoadUserId() -> String {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "userid") as? String ?? ""
    }
    
    class func DeleteUserId() {
        UserDefaults.standard.removeObject(forKey: "userid")
    }
    
    class func SaveUserName(username: String) {
        let defaults = UserDefaults.standard
        defaults.set(username, forKey: "username")
        defaults.synchronize()
    }
    
    class func LoadUserName() -> String {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "username") as? String ?? ""
    }
    
    class func SavePassword(password: String) {
        let defaults = UserDefaults.standard
        defaults.set(password, forKey: "password")
        defaults.synchronize()
    }
    
    class func LoadPassword() -> String {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "password") as? String ?? ""
    }
    
    class func SaveForgotPasswordToken(token: String) {
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "forgotPasswordToken")
        defaults.synchronize()
    }
    
    class func LoadForgotPasswordToken() -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "forgotPasswordToken")
    }
    
    class func DeleteForgotPasswordToken() {
        UserDefaults.standard.removeObject(forKey: "forgotPasswordToken")
    }
    
    class func SaveLastNotificationID(id: String) {
        let defaults = UserDefaults.standard
        defaults.set(id, forKey: "lastNotificationID")
        defaults.synchronize()
    }
    
    class func LoadLastNotificationID() -> String {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "lastNotificationID") as? String ?? ""
    }
    
    class func SaveFirstLoad(firstLoad: Int) {
        
        KeychainService.saveFirstLoad(firstLoad: "\(firstLoad)" as NSString)
        
    }
    
    class func LoadFirstLoad() -> Int {
        let firstLoad = KeychainService.loadFirstLoad() as String? ?? ""
        return firstLoad == "" ? 0 : Int(firstLoad)!
    }
    
}
