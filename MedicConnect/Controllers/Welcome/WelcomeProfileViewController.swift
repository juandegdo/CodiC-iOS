//
//  WelcomeProfileViewController.swift
//  MedicConnect
//
//  Created by alessandro on 2/23/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import AVFoundation
import ACFloatingTextfield
import TwitterKit
import Alamofire
import FacebookCore

class WelcomeProfileViewController: BaseViewController, UINavigationControllerDelegate {
    
    @IBOutlet var btnAvatarImage: UIButton!
//    @IBOutlet var btnMicrophone: UIButton!
    @IBOutlet var btnNotifications: UIButton!
    @IBOutlet var btnSave: UIButton!
    
    @IBOutlet var tfDescription: ACFloatingTextField!
    
    @IBOutlet var pageControl: UIPageControl!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var avatarImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateNotificationButton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(WelcomeProfileViewController.applicationIsActive(_:)), name:NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        avatarImageView.isHidden = true
        
        // If Twitter signed up, pull profile image from Twitter.
        let store = Twitter.sharedInstance().sessionStore
        if let userID = store.session()?.userID {
            let client = TWTRAPIClient.withCurrentUser()
            btnSave.isEnabled = false
            
            client.loadUser(withID: userID, completion: { (user, error) in
                if let u = user, let url = URL.init(string: u.profileImageLargeURL) {
                    print(u.profileImageLargeURL)
                    self.btnAvatarImage.setImage(UIImage.init(), for: .normal)
                    self.avatarImageView.af_setImage(withURL: url)
                    self.avatarImageView.isHidden = false
                    self.btnSave.isEnabled = true
                }
            })
        }
        
        // If Facebook signed up, pull profile image from Facebook
        if let accessToken = AccessToken.current {
            let request = GraphRequest(graphPath: "me", parameters: ["fields": "id"], accessToken: accessToken, httpMethod: .GET, apiVersion: FacebookCore.GraphAPIVersion.defaultVersion)
            request.start { (response, result) in
                switch result {
                case .success(let value):
                    if let fbUser = value.dictionaryValue, let userId = fbUser["id"] as? String {
                        let profileImageLargeURL = "http://graph.facebook.com/\(userId)/picture?type=large"
                        let imageURL = URL.init(string: profileImageLargeURL)
                        self.btnAvatarImage.setImage(UIImage.init(), for: .normal)
                        self.avatarImageView.af_setImage(withURL: imageURL!)
                        self.avatarImageView.isHidden = false
                        self.btnSave.isEnabled = true
                    }
                case .failed(let error):
                    print(error)
                    break
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        self.btnMicrophone.setCornered()
        self.btnNotifications.setCornered()
        self.btnNotifications.setBackgroundColor(color: UIColor.init(white: 1, alpha: 0.25), forState: .selected)
        
        self.pageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func applicationIsActive(_ notification: NSNotification) {
        self.updateNotificationButton()
    }
    
    func openImagePicker(isGalleryMode: Bool) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = isGalleryMode ? .photoLibrary : .camera
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func updateNotificationButton() {
        if NotificationUtil.isEnabledPushNotification() {
            self.btnNotifications.isSelected = true
            self.btnNotifications.setTitle("TURN OFF NOTIFICATIONS", for: .normal)
        } else {
            self.btnNotifications.isSelected = false
            self.btnNotifications.setTitle("TURN ON NOTIFICATIONS", for: .normal)
        }
    }
    
}

extension WelcomeProfileViewController {
    @IBAction func tapPicture(_ sender: Any) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let galleryAction = UIAlertAction(title: NSLocalizedString("Choose from Album", comment: "comment"), style: .default) {
            action in
            self.openImagePicker(isGalleryMode: true)
        }
        alertController.addAction(galleryAction)
        
        let camAction = UIAlertAction(title: NSLocalizedString("Take a Photo", comment: "comment"), style: .destructive) {
            action in
            self.openImagePicker(isGalleryMode: false)
        }
        alertController.addAction(camAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "comment"), style: .cancel) {
            action in
        }
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true) {
        }
        
        
    }
    @IBAction func tapMicrophone(_ sender: Any) {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() {
                (allowed) in
                if(allowed){
                    let alertController = UIAlertController(title: "Success", message: "You've already enabled microphone.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    
                    self.present(alertController, animated: false, completion: nil)
                }else{
                    self.processMicrophoneSettings()
                }
            }
        } catch {
        }
    }
    func processMicrophoneSettings() {
        let alertController = UIAlertController(title: "Setting", message: "You've already disabled microphone.\nGo to settings and enable microphone please.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        let goAction = UIAlertAction(title: "Go", style: .cancel) { (action) in
            NotificationUtil.goToAppSettings()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(goAction)
        
        if let w = UIApplication.shared.delegate?.window, let vc = w?.rootViewController {
            vc.present(alertController, animated: false, completion: nil)
        }
    }
    
    func processNotificationSettings(_ enabled: Bool) {
        let message = enabled ? "You've already enabled notification.\nGo to settings to disable notification." : "You've already disabled notification.\nGo to settings to enable notification."
        let alertController = UIAlertController(title: "Setting", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        let goAction = UIAlertAction(title: "Go", style: .cancel) { (action) in
            NotificationUtil.goToAppSettings()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(goAction)
        
        if let w = UIApplication.shared.delegate?.window, let vc = w?.rootViewController {
            vc.present(alertController, animated: false, completion: nil)
        }
    }
    
    @IBAction func tapNotifications(_ sender: Any) {
        
        self.processNotificationSettings(self.btnNotifications.isSelected)
        
    }
    
    @IBAction func tapSave(_ sender: Any) {
        
        if let _user = UserController.Instance.getUser() as User? {
            
            if self.tfDescription.text != "" {
                _user.description = self.tfDescription.text!
                
                UserService.Instance.editUser(user: _user, completion: {
                    (success: Bool, message: String) in
                    if !success {
                        if !message.isEmpty {
                            AlertUtil.showOKAlert(self, message: message)
                        }
                    }
                    
                })
            }
            
            if let _image = self.avatarImageView.image {
                
                self.btnSave.isEnabled = false
                UserService.Instance.postUserImage(id: _user.id, image: _image, completion: {
                    (success: Bool) in
                    print("\(success) uploading image.")
                    
                    if success {
                        UserService.Instance.getMe(completion: {
                            (user: User?) in
                            
                            self.btnSave.isEnabled = true
                            
                            self.navigationController?.popToRootViewController(animated: false)
                            
                            print("\(success) refreshing user info.")
                            
                        })
                    } else {
                        AlertUtil.showOKAlert(self, message: "Uplading your profile image failed. Try again.")
                    }
                })
                
            } else {
                self.navigationController?.popToRootViewController(animated: false)
            }
            
        } else {
            print("No user found")
        }
        
    }
    
    @IBAction func tapSkip(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: false)
    }
    
}

extension WelcomeProfileViewController : UIImagePickerControllerDelegate{

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let _image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.btnAvatarImage.setImage(UIImage.init(), for: .normal)
            self.avatarImageView.image = _image
            self.avatarImageView.isHidden = false
        }
        
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

