//
//  SaveBroadcastViewController.swift
//  MedicConnect
//
//  Created by alessandro on 12/4/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import IQDropDownTextField
import TLTagsControl
import MobileCoreServices

class SaveBroadcastViewController: BaseViewController {

    var activityIndicatorView = UIActivityIndicatorView()
    
    var isLiveBroadCast: Bool = false
    var fileURL: URL?
    
    @IBOutlet var imgAvatar: UIImageView!
    @IBOutlet var btnAddPicture: UIButton!
    
    @IBOutlet var tfAuthor: UITextField!
    @IBOutlet var tfBroadcastName: UITextField!
    @IBOutlet var tvDescription: RadContentHeightTextView!
    @IBOutlet var hashTagCtrl: TLTagsControl!
    @IBOutlet var viewAuthorContraint: NSLayoutConstraint!
    @IBOutlet var alertWindow: UIWindow!
    @IBOutlet var btnSave: UIButton!
    
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
        super.viewDidDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
    }
    
    //MARK: Initialize views
    
    func initViews() {
        
        // Avatar
        self.imgAvatar.layer.borderWidth = 1.5
        self.imgAvatar.layer.borderColor = UIColor.white.cgColor
        
        _ = UIFont(name: "Avenir-Heavy", size: 18.0) as UIFont? ?? UIFont.systemFont(ofSize: 18.0)
        
        if let _user = UserController.Instance.getUser() as User? {
            if let imgURL = URL(string: _user.photo) as URL? {
                self.imgAvatar.af_setImage(withURL: imgURL)
            } else {
                self.imgAvatar.image = nil
            }
            
            self.tfAuthor.text = _user.fullName
            
        }
        
        // Add Picture Button
        self.btnAddPicture.layer.borderWidth = 1.5
        self.btnAddPicture.layer.borderColor = UIColor(red:152.0/255, green:163.0/255, blue:169.0/255, alpha:1.0).cgColor
        
        // Author
        self.viewAuthorContraint.constant = self.isLiveBroadCast ? 0 : 147
    
        // Description
        self.tvDescription.minHeight = 30
        self.tvDescription.maxHeight = 150
    
        // Hashtags
        self.hashTagCtrl.tagsBackgroundColor = UIColor(red: 205/255, green: 212/255, blue: 215/255, alpha: 1.0)
        self.hashTagCtrl.tagsTextColor = UIColor.white
        self.hashTagCtrl.tagsDeleteButtonColor = UIColor.white
        self.hashTagCtrl.reloadTagSubviews()
        
        // Save Broadcast Button
        self.btnSave.layer.cornerRadius = 4.0
        
        self.btnSave.layer.borderWidth = 1.5
        self.btnSave.layer.borderColor = UIColor(red:251.0/255, green:27.0/255, blue:70.0/255, alpha:1.0).cgColor
        
        self.btnSave.layer.shadowColor = UIColor(red:251.0/255, green:27.0/255, blue:70.0/255, alpha:1.0).cgColor
        self.btnSave.layer.shadowOpacity = 0.1
        self.btnSave.layer.shadowRadius = 8.0
        self.btnSave.layer.shadowOffset = CGSize.zero
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
}

extension SaveBroadcastViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        
        if (textField == self.tfBroadcastName) {
            return newLength <= Constants.MaxFullNameLength
        } else {
            return true
        }
        
    }
}

extension SaveBroadcastViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let description = textView.text else { return true }
        
        let newLength = description.characters.count + text.characters.count - range.length
        return newLength <= Constants.MaxDescriptionLength
    }
}

extension SaveBroadcastViewController : UINavigationControllerDelegate {
    //MARK: UIImagePickerControllerDelegate
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
    }
    
}

extension SaveBroadcastViewController : UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.imgAvatar.image = pickedImage
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

extension SaveBroadcastViewController {
    
    //MARK: IBActions
    
    func startIndicating(){
        activityIndicatorView.center = self.view.center
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.activityIndicatorViewStyle = .gray
        view.addSubview(activityIndicatorView)
        
        activityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func stopIndicating() {
        activityIndicatorView.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    @IBAction func onBack(sender: AnyObject!) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onSave(sender: UIButton) {
        
        let title = self.tfBroadcastName.text!
        guard  title.characters.count != 0 else {
            AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to give your broadcast a name!")
            return
        }
        self.startIndicating()
        
        var audioFilename: URL
        if (self.fileURL != nil) {
            audioFilename = self.fileURL!
        }
        else {
            audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        }
        let fileExtension = audioFilename.pathExtension
        let fileMimeType = fileExtension.mimeTypeForPathExtension()
        
        do {
            let audioData = try Data(contentsOf: audioFilename)
            
            
            self.btnSave.isEnabled = false
            
            PostService.Instance.sendPost(title, author: self.tfAuthor.text!, description: self.tvDescription.text!, hashtags: hashTagCtrl.tags as! [String], audioData: audioData, image: nil/*self.imgAvatar.image*/, fileExtension: fileExtension, mimeType: fileMimeType, completion: {
                (success: Bool) in
                
                // As we just posted a new video, it's a good thing to refresh user info.
                UserService.Instance.getMe(completion: {
                    (user: User?) in
                    
                    self.stopIndicating()
                    self.btnSave.isEnabled = true
                    self.performSegue(withIdentifier: Constants.SegueMedicConnectShareBroadcast, sender: nil)
                })
                
            })            
        } catch let error {
            self.stopIndicating()
            print(error.localizedDescription)
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

extension String {
    func mimeTypeForPathExtension() -> String {
        if let
            id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self as CFString, nil)?.takeRetainedValue(),
            let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue()
        {
            return contentType as String
        }
        
        return "application/octet-stream"
    }
}
