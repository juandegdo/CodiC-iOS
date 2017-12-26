//
//  WelcomeProfileViewController.swift
//  MedicConnect
//
//  Created by alessandro on 2/23/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import ACFloatingTextfield_Swift

class WelcomeProfileViewController: BaseViewController, UINavigationControllerDelegate {
    
    @IBOutlet var btnAvatarImage: UIButton!
    @IBOutlet var btnSave: UIButton!
    
    @IBOutlet var tfTitle: ACFloatingTextfield!
    @IBOutlet var tfMSP: ACFloatingTextfield!
    @IBOutlet var tfLocation: ACFloatingTextfield!
    @IBOutlet var tfPhoneNumber: ACFloatingTextfield!
    
    @IBOutlet var pageControl: UIPageControl!
    
    @IBOutlet var avatarImageView: UIImageView!
    
    var avatarImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
    }
    
    // MARK: Initialize Views
    
    func initViews() {
        
        // Avatar Image View
        self.avatarImageView.layer.borderColor  = UIColor.white.cgColor
        
        // Name
        self.tfTitle.placeholder = NSLocalizedString("Title", comment: "comment")
        
        // Email
        self.tfMSP.placeholder = NSLocalizedString("MSP #", comment: "comment")
        
        // Pasword
        self.tfLocation.placeholder = NSLocalizedString("Location", comment: "comment")
        
        // Pasword
        self.tfPhoneNumber.placeholder = NSLocalizedString("Phone #", comment: "comment")
        
        // Page Control
        self.pageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
    }
    
    func openImagePicker(isGalleryMode: Bool) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = isGalleryMode ? .photoLibrary : .camera
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
}

extension WelcomeProfileViewController {
    
    // MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
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
    
    @IBAction func tapSave(_ sender: Any) {
        
        if let _user = UserController.Instance.getUser() as User? {
            
            if self.tfTitle.text != "" {
                _user.title = self.tfTitle.text!
            } else {
                AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to fill in your title!")
                return
            }
            
            if self.tfMSP.text != "" {
                _user.msp = self.tfMSP.text!
            } else {
                AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to fill in your MSP number!")
                return
            }
            
            if self.tfLocation.text != "" {
                _user.location = self.tfLocation.text!
            } else {
                AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to fill in your location!")
                return
            }
            
            if self.tfPhoneNumber.text != "" {
                _user.phoneNumber = self.tfPhoneNumber.text!
            } else {
                AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to fill in your phone number!")
                return
            }
            
            UserService.Instance.editUser(user: _user, completion: {
                (success: Bool, message: String) in
                if !success {
                    if !message.isEmpty {
                        AlertUtil.showOKAlert(self, message: message)
                    }
                }
            })
            
            if let _image = self.avatarImageView.image {
                
                self.btnSave.isEnabled = false
                UserService.Instance.postUserImage(id: _user.id, image: _image, completion: {
                    (success: Bool) in
                    print("\(success) uploading image.")
                    
                    if success {
                        UserService.Instance.getMe(completion: {
                            (user: User?) in
                            
                            self.btnSave.isEnabled = true
                            
                            self.performSegue(withIdentifier: Constants.SegueMedicConnectWelcomeLast, sender: nil)
                            
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
    
}

extension WelcomeProfileViewController : UIImagePickerControllerDelegate{

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let _image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.btnAvatarImage.setImage(UIImage.init(), for: .normal)
            self.avatarImageView.image = _image
        }
        
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

