//
//  EditProfileViewController.swift
//  MedicConnect
//
//  Created by alessandro on 11/28/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit

let updatedProfileNotification = NSNotification.Name(rawValue:"userUpdated")

class EditProfileViewController: BaseViewController {
    
    @IBOutlet var imgAvatar: RadAvatar!
    @IBOutlet var tvDescription: RadContentHeightTextView!
    @IBOutlet var txFieldName: UITextField!
    @IBOutlet var txFieldPhoneNumber: UITextField!
    @IBOutlet var txFieldEmail: UITextField!
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
    
    // MARK: Private methods
    
    func initViews() {
        
        self.txFieldEmail.isEnabled = false
        
        if let _user = UserController.Instance.getUser() as User? {
            
            // Customize Avatar
            _ = UIFont(name: "Avenir-Heavy", size: 18.0) as UIFont? ?? UIFont.systemFont(ofSize: 18.0)
                        
            if let imgURL = URL(string: _user.photo) as URL? {
                self.imgAvatar.af_setImage(withURL: imgURL)
            } else {
                self.imgAvatar.image = nil
            }
            
            self.txFieldName.text = _user.fullName
            self.txFieldEmail.text = _user.email
            self.txFieldPhoneNumber.text = _user.phoneNumber
            self.tvDescription.text = _user.description
            
            // Customize Description
            self.tvDescription.minHeight = 50.0
            self.tvDescription.maxHeight = 150.0
        }
        
        // Change Picture Button
        self.btnChangePicture.layer.cornerRadius = 3
        self.btnChangePicture.clipsToBounds = true
        self.btnChangePicture.layer.borderColor = UIColor.init(red: 18/255.0, green: 42/255.0, blue: 54/255.0, alpha: 1.0).cgColor
        self.btnChangePicture.layer.borderWidth = 1
        self.btnChangePicture.setBackgroundColor(color: UIColor.init(white: 0.2, alpha: 1.0), forState: .highlighted)
        
        // Save Button
        self.btnSave.layer.cornerRadius = 3
        self.btnSave.clipsToBounds = true
        self.btnSave.layer.borderColor = UIColor.init(red: 255/255.0, green: 13/255.0, blue: 13/255.0, alpha: 1.0).cgColor
        self.btnSave.layer.borderWidth = 1
        self.btnSave.setBackgroundColor(color: UIColor.init(white: 0.5, alpha: 1.0), forState: .highlighted)
        
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
        
        if (textField == self.txFieldName) {
            return newLength <= Constants.MaxFullNameLength
        } else { /// phone number
            return newLength <= Constants.MaxPhoneNumberLength
        }
        
    }
}

extension EditProfileViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let description = textView.text else { return true }
        let newLength = description.characters.count + text.characters.count - range.length
        
        return newLength <= Constants.MaxDescriptionLength
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
            
            _user.fullName = self.txFieldName.text!
            _user.description = self.tvDescription.text!
            _user.phoneNumber = self.txFieldPhoneNumber.text!
            
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
