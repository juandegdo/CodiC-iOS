//
//  PreRecordingBroadcastViewController.swift
//  MedicConnect
//
//  Created by alessandro on 12/3/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import AVFoundation

class PreRecordingBroadcastViewController: BaseViewController {
    
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserService.Instance.updateAvailability(available: false) { (success) in
            if (success) {
                // Do nothing now
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
    }
    
}

extension PreRecordingBroadcastViewController {
    //MARK: IBActions
    
    func processMicrophoneSettings() {
        let alertController = UIAlertController(title: "Setting", message: "You've already disabled microphone.\nGo to settings and enable microphone please.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        let goAction = UIAlertAction(title: "Go", style: .cancel) { (action) in
            NotificationUtil.goToAppSettings()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(goAction)
        
        self.present(alertController, animated: false, completion: nil)
    }
    
    @IBAction func onRecordBroadcast(sender: AnyObject) {
        
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() {
                (allowed) in
                DispatchQueue.main.async {
                    // Run UI Updates
                    if (allowed) {
                        self.performSegue(withIdentifier: Constants.SegueMedicConnectRecordingBroadcast, sender: nil)
                    } else {
                        try? recordingSession.setActive(false)
                        self.processMicrophoneSettings()
                    }
                }
            }
        } catch {
        }
    }
    
    @IBAction func onClose(sender: AnyObject) {
        
        UserService.Instance.updateAvailability(available: true) { (success) in
            if (success) {
                // Do nothing now
            }
        }
        
        if let _nav = self.navigationController as UINavigationController? {
            _nav.dismiss(animated: false, completion: nil)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
}
