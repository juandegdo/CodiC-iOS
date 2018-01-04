//
//  AppDelegate.swift
//  MedicConnect
//
//  Created by alessandro on 11/22/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import IQKeyboardManager
import Fabric
import Crashlytics
import UserNotifications
import CoreData
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var launchedURL: URL? = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics.self])
        
        // Check launched URL for reset password
        self.launchedURL = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL
        
        // IQKeyboardManager Settings
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().isEnableAutoToolbar = true
        IQKeyboardManager.shared().previousNextDisplayMode = .alwaysHide
        IQKeyboardManager.shared().shouldShowToolbarPlaceholder = true
        IQKeyboardManager.shared().toolbarManageBehaviour = IQAutoToolbarManageBehaviour.bySubviews

        NotificationUtil.makeUserNotificationEnabled()
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        } else {
            // Fallback on earlier versions
        }
        
        // Enable playing audio in silent mode
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        }
        catch {
            print("Failed to enable playing audio in silent mode")
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if url.absoluteString.lowercased().contains("medicconnectlink") && UserDefaultsUtil.LoadToken().isEmpty {
            self.openLink(url: url, fromLaunch: false)
            return true
        }
        
        return false
        
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if self.launchedURL != nil && UserDefaultsUtil.LoadToken().isEmpty {
            self.openLink(url: self.launchedURL!, fromLaunch: true)
            self.launchedURL = nil
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        self.saveContext()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("========Received========\n\(userInfo)\n")
        
        if let dictInfo = userInfo["aps"] as? NSDictionary {
            if  let _ = UserController.Instance.getUser() as User? {
                NotificationUtil.updateNotificationAlert(hasNewAlert: true)
            }
            
            if let id = dictInfo["id"] as? String {
                // Save notification id
                UserDefaultsUtil.SaveLastNotificationID(id: id)
                
                NotificationService.Instance.markAsRead(id, completion: { (success, count) in
                    if (success) {
                        application.applicationIconBadgeNumber = count! >= 0 ? count! : 0
                    }
                })
                
                NotificationService.Instance.getNotifications { (success) in
                    print("notification: \(success)")
                }
            }
            
            if application.applicationState != .active {
                // Only show views if app is not active
                if let type = dictInfo["type"] as? Int, let notificationType = NotificationType(rawValue: type) {
                    switch notificationType {
                    case .like:
                        NotificationCenter.default.post(name: NSNotification.Name("gotoProfileScreen"), object: nil, userInfo: nil)
                        break
                    case .comment:
                        if let postId = dictInfo["broadcast"] as? String {
                            self.callCommentVC(id: postId)
                        }
                        break
                    case .broadcast, .newFollower:
                        if let userId = dictInfo["user"] as? String {
                            UserService.Instance.getUser(forId: userId, completion: { (user) in
                                if let user = user {
                                    self.callProfileVC(user: user)
                                }
                            })
                        }
                        break
                    default:
                        self.callNotificationVC()
                        break
                    }
                }
            } else if let topVC = self.window?.visibleViewController() as? NotificationsViewController {
                // Notification controller is currently presenting
                topVC.loadNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print(deviceTokenString)
        UserController.Instance.setDeviceToken(deviceTokenString)
        
        if let _me = UserController.Instance.getUser() as User? {
            
            UserService.Instance.putDeviceToken(deviceToken: deviceTokenString) { (success) in
                if (success) {
                    _me.deviceToken = deviceTokenString
                }
            }
            
        }
        
        // Persist it in your backend in case it's new
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Handle push from foreground")
        if  let _ = UserController.Instance.getUser() as User? {
            NotificationUtil.updateNotificationAlert(hasNewAlert: true)
        }
        completionHandler([.alert,.sound])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let _ = response.notification.request.content.userInfo as? [String : AnyObject] {
            // Getting user info
            if  let _ = UserController.Instance.getUser() as User? {
                NotificationUtil.updateNotificationAlert(hasNewAlert: true)
            }
        }
        completionHandler()
    }
    
    // MARK: - Private Methods
    
    func openLink(url: URL, fromLaunch: Bool) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (fromLaunch ? 0.8 : 0.0)) {
            let notificationName = "goToResetPassword"
            let data:[String: String] = ["token": url.lastPathComponent]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationName), object: nil, userInfo: data)
        }
    }
    
    func callNotificationVC() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NotificationVC")
        if let vvc = self.window?.visibleViewController() {
            vvc.present(vc, animated: false, completion: nil)
        }
    }
    
    func callProfileVC(user: User) {
        
        if  let _me = UserController.Instance.getUser() as User? {
            if _me.id == user.id {
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if  let vc = storyboard.instantiateViewController(withIdentifier: "AnotherProfileViewController") as? AnotherProfileViewController {
                
                vc.currentUser = user
                if let vvc = self.window?.visibleViewController() {
                    vvc.present(vc, animated: false, completion: nil)
                }
            }
        }
        
    }
    
    func callCommentVC(id: String) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            if let _user = UserController.Instance.getUser() {
                let arrPosts = _user.getPosts(type: "")
                for post in arrPosts {
                    if post.id == id {
                        vc.currentPost = post
                        if let vvc = self.window?.visibleViewController() {
                            vvc.present(vc, animated: false, completion: nil)
                        }
                        break
                    }
                }
                
            }
            
            
        }
        
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "playlist")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

extension UIWindow {
    func visibleViewController() -> UIViewController? {
        if let rootViewController = self.rootViewController {
            return UIWindow.getVisibleViewControllerFrom(vc: rootViewController)
        }
        return nil
    }
    
    class func getVisibleViewControllerFrom(vc: UIViewController) -> UIViewController {
        if vc.isKind(of: UINavigationController.self) {
            let nc = vc as! UINavigationController
            return UIWindow.getVisibleViewControllerFrom(vc: nc.visibleViewController!)
        } else if(vc.isKind(of: UITabBarController.self)) {
            let tc = vc as! UITabBarController
            return UIWindow.getVisibleViewControllerFrom(vc: tc.selectedViewController!)
        } else {
            if let pc = vc.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(vc: pc)
            } else {
                return vc
            }
        }
    }
}
