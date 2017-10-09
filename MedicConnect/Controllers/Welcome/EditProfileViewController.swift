//
//  EditProfileViewController.swift
//  MedicConnect
//
//  Created by alessandro on 11/28/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import ACFloatingTextfield

let updatedProfileNotification = NSNotification.Name(rawValue:"userUpdated")

class EditProfileViewController: BaseViewController {
    
    @IBOutlet var imgAvatar: RadAvatar!
    @IBOutlet var tfName: ACFloatingTextField!
    @IBOutlet var tfTitle: ACFloatingTextField!
    @IBOutlet var tfMSP: ACFloatingTextField!
    @IBOutlet var tfLocation: ACFloatingTextField!
    @IBOutlet var tfPhoneNumber: ACFloatingTextField!
    @IBOutlet var tfEmail: ACFloatingTextField!
    @IBOutlet var btnChangePicture: UIButton!
    @IBOutlet var btnSave: UIButton!
    
    var alertWindow: UIWindow!
    
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: Initialize Views
    
    func initViews() {
        
        // Name
        self.tfName.placeholder = NSLocalizedString("Name", comment: "comment")
        
        // Title
        self.tfTitle.placeholder = NSLocalizedString("Title", comment: "comment")
        
        // MSP
        self.tfMSP.placeholder = NSLocalizedString("MSP #", comment: "comment")
        
        // Location
        self.tfLocation.placeholder = NSLocalizedString("Location", comment: "comment")
        
        // Phone Number
        self.tfPhoneNumber.placeholder = NSLocalizedString("Phone #", comment: "comment")
        
        // Email
        self.tfEmail.placeholder = NSLocalizedString("Email", comment: "comment")
        
        self.tfEmail.isEnabled = false
        
        if let _user = UserController.Instance.getUser() as User? {
            
            // Customize Avatar
            if let imgURL = URL(string: _user.photo) as URL? {
                self.imgAvatar.af_setImage(withURL: imgURL)
            } else {
                self.imgAvatar.image = nil
            }
            
            self.tfName.text = _user.fullName
//            self.tfTitle.text = _user.title
//            self.tfMSP.text = _user.msp
//            self.tfLocation.text = _user.location
            self.tfEmail.text = _user.email
            self.tfPhoneNumber.text = _user.phoneNumber
            
        }
        
        // Change Picture Button
        self.btnChangePicture.layer.cornerRadius = 14
        self.btnChangePicture.clipsToBounds = true
        self.btnChangePicture.layer.borderColor = UIColor.init(red: 113/255.0, green: 127/255.0, blue: 134/255.0, alpha: 1.0).cgColor
        self.btnChangePicture.layer.borderWidth = 1
        
        // Save Button
//        self.btnSave.layer.cornerRadius = 3
//        self.btnSave.clipsToBounds = true
//        self.btnSave.layer.borderColor = UIColor.init(red: 255/255.0, green: 13/255.0, blue: 13/255.0, alpha: 1.0).cgColor
//        self.btnSave.layer.borderWidth = 1
//        self.btnSave.setBackgroundColor(color: UIColor.init(white: 0.5, alpha: 1.0), forState: .highlighted)
        
    }
    
    func uploadImage() {
        
        if let _user = UserController.Instance.getUser() as User? {
            
            if let _image = self.imgAvatar.image as UIImage? {
                
                //SwiftSpinner.show("Uploading image...")
                self.btnSave.makeEnabled(enabled: false)
                UserService.Instance.postUserImage(id: _user.id, image: _image, completion: {
                    (success: Bool) in
                    
                    print("\(success) uploading image.")
                    
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        
                        let nc = NotificationCenter.default
                        nc.post(name: updatedProfileNotification, object: nil, userInfo: nil)
                        //SwiftSpinner.hide()
                        self.btnSave.makeEnabled(enabled: true)
                                                                        
                    })
                    
                })
                
            } else {
                print("No image found")
            }
            
        } else {
            print("No user found")
        }
        
    }
    
}

extension EditProfileViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        
        if (textField == self.tfName) {
            return newLength <= Constants.MaxFullNameLength
        } else if (textField == self.tfPhoneNumber) { /// phone number
            return newLength <= Constants.MaxPhoneNumberLength
        }
        
        return true
        
    }
}

extension EditProfileViewController : UINavigationControllerDelegate {
    
    //MARK: UIImagePickerControllerDelegate
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
    }
}

extension EditProfileViewController : UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var isChanged = false
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.imgAvatar.image = pickedImage
            isChanged = true
        }

        dismiss(animated: true) {
            if(isChanged){
                self.uploadImage()
            }
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

extension EditProfileViewController {
    
    // MARK: IBActions
    
    @IBAction func onBack(sender: AnyObject!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onSaveChange(sender: AnyObject!) {
        
        if let _user = UserController.Instance.getUser() as User? {
            
            _user.fullName = self.tfName.text!
//            _user.title = self.tfTitle.text!
//            _user.msp = self.tfMSP.text!
//            _user.location = self.tfLocation.text!
            _user.phoneNumber = self.tfPhoneNumber.text!
            
            //SwiftSpinner.show("Updating user...")
            self.btnSave.isEnabled = false
            UserService.Instance.editUser(user: _user, completion: {
                (success: Bool, message: String) in
                //SwiftSpinner.hide()
                self.btnSave.isEnabled = true
                
                if success {
                    self.onBack(sender: nil)
                } else {
                    if !message.isEmpty {
                        AlertUtil.showOKAlert(self, message: message)
                    }
                }
                
            })
            
        } else {
            self.onBack(sender: nil)
        }
    
    }
    
    @IBAction func onChangePhoto(sender: AnyObject!) {
        
        self.alertWindow = UIWindow(frame: UIScreen.main.bounds)
        self.alertWindow.rootViewController = UIViewController()
        self.alertWindow.windowLevel = 10000001
        self.alertWindow.isHidden = false
        
        let alert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Choose from Albums
        let albumAction = UIAlertAction(title: NSLocalizedString("Choose from Album", comment: "comment"), style: .default, handler: {
            (act: UIAlertAction) in
            let sourceType = UIImagePickerControllerSourceType.photoLibrary
            if UIImagePickerController.isSourceTypeAvailable(sourceType) {
                let picker = UIImagePickerController()
                picker.sourceType = sourceType
                picker.delegate = self
                picker.allowsEditing = true
                self.present(picker, animated: true, completion: nil)
            }
            self.alertWindow.isHidden = true
            self.alertWindow = nil
        })
        alert.addAction(albumAction)
        
        // Take a Photo
        let photoAction = UIAlertAction(title: NSLocalizedString("Take a Photo", comment: "comment"), style: .destructive, handler: {
            (act: UIAlertAction) in
            let sourceType = UIImagePickerControllerSourceType.camera
            if UIImagePickerController.isSourceTypeAvailable(sourceType) {
                let picker = UIImagePickerController()
                picker.sourceType = sourceType
                picker.delegate = self
                picker.allowsEditing = true
                self.present(picker, animated: true, completion: nil)
            }
            self.alertWindow.isHidden = true
            self.alertWindow = nil
        })
        alert.addAction(photoAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "comment"), style: .default, handler: {
            (act: UIAlertAction) in
            self.alertWindow.isHidden = true
            self.alertWindow = nil
        })
        alert.addAction(cancelAction)
        
        alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
        
    }
    
}
