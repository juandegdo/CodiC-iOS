//
//  SplashViewController.swift
//  MedicConnect
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
                    
                    UserDefaultsUtil.SaveUserId(userid: (user?.id)!)
                    NotificationUtil.makeUserNotificationEnabled()
                    
                    // Configure VOIP and sinch client
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.voipRegistration()
                    appDelegate.configureSinchClient(_user.id)
                    
                    // Update user availability
                    UserService.Instance.updateAvailability(available: true) { (success) in
                        if (success) {
                            // Do nothing now
                        }
                    }
                    
                    self.requestPermissions()
                    
                    self.performSegue(withIdentifier: Constants.SegueMedicConnectHome, sender: nil)
                } else {
                    // User not logged in properly
                    UserDefaultsUtil.DeleteUserId()
                    self.performSegue(withIdentifier: Constants.SegueMedicConnectSignIn, sender: nil)
                }
            })
            
        } else {
            // User not logged in
            UserDefaultsUtil.DeleteUserId()
            self.performSegue(withIdentifier: Constants.SegueMedicConnectSignIn, sender: nil)
        }
        
    }
    
    func requestPermissions() {
        
        //Microphone
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() {
                (allowed) in
                DispatchQueue.main.async {
                    // Run UI Updates
                    if (allowed) {
                        
                    } else {
                        try? recordingSession.setActive(false)
                        self.processMicrophoneSettings("You've already disabled microphone.\nGo to settings and enable microphone please.")
                    }
                }
            }
        } catch {
        }
        
        //Camera
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //access granted
            } else {
                self.processMicrophoneSettings("You've already disabled camera.\nGo to settings and enable camera please.")
            }
        }
        
    }
    
    func processMicrophoneSettings(_ message: String) {
        let alertController = UIAlertController(title: "Setting", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        let goAction = UIAlertAction(title: "Go", style: .cancel) { (action) in
            NotificationUtil.goToAppSettings()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(goAction)
        
        self.present(alertController, animated: false, completion: nil)
    }

}
