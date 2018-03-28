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
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, PKPushRegistryDelegate {
    
    static let kSinchApplicationKey = "7297db41-4f67-499c-940d-1edff525d48e"
    static let kSinchApplicationSecret = "BcDM5Av1XkGLb3z5DLiK4A=="
    static let kSinchHostname = "sandbox.sinch.com" // devlopment
//    static let kSinchHostname = "clientapi.sinch.com" // production

    var window: UIWindow?
    var launchedURL: URL? = nil
    var orientationLock = UIInterfaceOrientationMask.portrait
    
    var sinchClient: SINClient?
    var sinchPush: SINManagedPush?
    var sinchCallKitProvider: SINCallKitProvider?

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
        
        self.voipRegistration()
        
        // Enable playing audio in silent mode
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        }
        catch {
            print("Failed to enable playing audio in silent mode")
        }
        
        // Sinch Push
        self.sinchPush = Sinch.managedPush(with: SINAPSEnvironment.development)  // needs to be changed to production
        self.sinchPush?.delegate = self
        self.sinchPush?.setDesiredPushTypeAutomatically()
        
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
        if let call = self.sinchCallKitProvider?.currentEstablishedCall() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if  let vc = storyboard.instantiateViewController(withIdentifier: "CallScreenViewController") as? CallScreenViewController {
                vc.call = call
                vc.fromCallKit = true
                
                if let vvc = self.window?.rootViewController {
                    vvc.present(vc, animated: false, completion: nil)
                }
            }
        }
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
        
        self.sinchPush?.application(application, didReceiveRemoteNotification: userInfo)
        
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
                    case .broadcast:
                        NotificationCenter.default.post(name: NSNotification.Name("gotoProfileScreen"), object: nil, userInfo: nil)
//                        if let userId = dictInfo["user"] as? String {
//                            UserService.Instance.getUser(forId: userId, completion: { (user) in
//                                if let user = user {
//                                    self.callProfileVC(user: user)
//                                }
//                            })
//                        }
                        break
                    case .transcribed:
                        NotificationCenter.default.post(name: NSNotification.Name("gotoProfileScreen"), object: nil, userInfo: nil)
                        
                        break
                    default:
                        self.callNotificationVC()
                        break
                    }
                }
            } else if let topVC = self.window?.visibleViewController() as? ProfileViewController {
                // Reload profile view
                topVC.initViews()
                
            } else if let topVC = self.window?.visibleViewController() as? NotificationsViewController {
                // Notification controller is currently presenting
                topVC.loadNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Add to sinch
        self.sinchPush?.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // Convert token to string
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print(deviceTokenString)
        UserController.Instance.setDeviceToken(deviceTokenString)
        
        if let _me = UserController.Instance.getUser() as User? {
            
            // Add to server
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
//            if  let _ = UserController.Instance.getUser() as User? {
//                NotificationUtil.updateNotificationAlert(hasNewAlert: true)
//            }
        }
        completionHandler()
    }
    
    // MARK: - PushKit Delegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        self.handleRemoteNotification(payload.dictionaryPayload)
    }
    
    // MARK: - Private Methods
    
    func voipRegistration() {
        // Register for VoIP notifications
        let mainQueue = DispatchQueue.main
        // Create a push registry object
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        // Set the registry's delegate to self
        voipRegistry.delegate = self
        // Set the push type to VoIP
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
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
    
    // MARK: - Orientation
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    
    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }
        
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
            self.lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }
    
    // MARK: - Sinch
    
    func configureSinchClient(_ userId: String) {
        
        self.sinchPush?.registerUserNotificationSettings()
        
        // Instantiate a Sinch client object
        self.sinchClient = Sinch.client(withApplicationKey: AppDelegate.kSinchApplicationKey,
                                        applicationSecret: AppDelegate.kSinchApplicationSecret,
                                        environmentHost: AppDelegate.kSinchHostname,
                                        userId: userId)
        
        // Assign as SINClientDelegate
        self.sinchClient?.delegate = self
        self.sinchClient?.call().delegate = self
        
        // Specify the client capabilities.
        // (At least one of the messaging or calling capabilities should be enabled.)
        self.sinchClient?.setSupportCalling(true)
        self.sinchClient?.setSupportPushNotifications(true)
        
        self.sinchClient?.enableManagedPushNotifications()
        
        // Start the Sinch Client
        self.sinchClient?.start()
        
        // Start listening for incoming calls and messages
        self.sinchClient?.startListeningOnActiveConnection()
        
        self.sinchCallKitProvider = SINCallKitProvider.init(client: self.sinchClient!)
        
    }
    
    func handleRemoteNotification(_ userInfo: [AnyHashable : Any]) {
        if self.sinchClient == nil {
            if let _me = UserController.Instance.getUser() as User? {
                self.configureSinchClient(_me.id)
            }
        }
        
        let result: SINNotificationResult? = self.sinchClient?.relayRemotePushNotification(userInfo)
        
        if ((result != nil) && (result?.isCall())! && (result?.call().isTimedOut)!) {
            self.presentMissedCallNotificationWithRemoteUserId((result?.call().remoteUserId)!)
        }
    }
    
    func presentMissedCallNotificationWithRemoteUserId(_ remoteUserId: String) {
//        UIApplication *application = [UIApplication sharedApplication];
//        if ([application applicationState] == UIApplicationStateBackground) {
//            UILocalNotification *note = [[UILocalNotification alloc] init];
//            note.alertBody = [NSString stringWithFormat:@"Missed call from %@", remoteUserId];
//            note.alertTitle = @"Missed call";
//            [application presentLocalNotificationNow:note];
//        }
    }

}

extension AppDelegate: SINClientDelegate {
    
    func clientDidStart(_ client: SINClient!) {
        print("client did start")
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        print("client did fail: \(error.localizedDescription)")
    }
    
    func client(_ client: SINClient!, logMessage message: String!, area: String!, severity: SINLogSeverity, timestamp: Date!) {
        print(message)
    }
    
}

extension AppDelegate: SINCallClientDelegate {
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if  let vc = storyboard.instantiateViewController(withIdentifier: "CallScreenViewController") as? CallScreenViewController {
            vc.call = call
            if let vvc = self.window?.rootViewController {
                vvc.present(vc, animated: false, completion: nil)
            }
        }
    }
    
    func client(_ client: SINCallClient!, willReceiveIncomingCall call: SINCall!) {
        self.sinchCallKitProvider?.reportNewIncomingCall(call)
    }
    
//    func client(_ client: SINCallClient!, localNotificationForIncomingCall call: SINCall!) -> SINLocalNotification! {
//        let notification: SINLocalNotification = SINLocalNotification.init()
//        notification.alertAction = "Answer"
//        notification.alertBody = "Incoming call"
//        return notification
//    }
    
}

extension AppDelegate: SINManagedPushDelegate {
    
    func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable : Any]!, forType pushType: String!) {
        print(payload)
        self.handleRemoteNotification(payload)
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
