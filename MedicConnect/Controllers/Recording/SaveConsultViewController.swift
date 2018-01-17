//
//  SaveConsultViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2018-01-17.
//  Copyright © 2018 Loewen. All rights reserved.
//

import UIKit
import TLTagsControl
import MobileCoreServices

class SaveConsultViewController: BaseViewController {
    
    var activityIndicatorView = UIActivityIndicatorView()
    var fileURL: URL?
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblPostTitle: UILabel!
    @IBOutlet var lblPostDescription: UILabel!
    
    @IBOutlet var tfBroadcastName: UITextField!
    @IBOutlet var tvDescription: RadContentHeightTextView!
    @IBOutlet var tfDiagnosticCode: UITextField!
    @IBOutlet var tfBillingCode: UITextField!
    @IBOutlet var hashTagCtrl: TLTagsControl!
    
    @IBOutlet var btnSave: UIButton!
    @IBOutlet var alertWindow: UIWindow!
    
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
        
        // Title
        self.lblTitle.text = "Save \(DataManager.Instance.getPostType() == Constants.PostTypeConsult ? Constants.PostTypeConsult : "Patient \(Constants.PostTypeNote)")"
        self.lblPostTitle.text = "\(DataManager.Instance.getPostType()) Title"
        self.lblPostDescription.text = "\(DataManager.Instance.getPostType() == Constants.PostTypeConsult ? Constants.PostTypeConsult : "Patient") Notes"
        self.btnSave.setTitle("SAVE \(DataManager.Instance.getPostType().uppercased())", for: .normal)
        
        // Description
        self.tvDescription.minHeight = 30
        self.tvDescription.maxHeight = 150
        
        // Hashtags
        self.hashTagCtrl.tagsBackgroundColor = UIColor(red: 205/255, green: 212/255, blue: 215/255, alpha: 1.0)
        self.hashTagCtrl.tagsTextColor = UIColor.white
        self.hashTagCtrl.tagsDeleteButtonColor = UIColor.white
        self.hashTagCtrl.reloadTagSubviews()
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
}

extension SaveConsultViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        if (textField == self.tfBroadcastName) {
            return newLength <= Constants.MaxFullNameLength
        } else {
            return true
        }
        
    }
}

extension SaveConsultViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let description = textView.text else { return true }
        
        let newLength = description.count + text.count - range.length
        return newLength <= Constants.MaxDescriptionLength
    }
}

extension SaveConsultViewController {
    
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
        activityIndicatorView.removeFromSuperview()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    @IBAction func onClose(sender: UIButton) {
        
        if let _nav = self.navigationController as UINavigationController? {
            _nav.dismiss(animated: false, completion: nil)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
        
    }
    
    @IBAction func onSave(sender: UIButton) {
        
        let postType = DataManager.Instance.getPostType()
        let title = self.tfBroadcastName.text!
        guard  title.count != 0 else {
            AlertUtil.showOKAlert(self, message: "Oops, it looks like you forgot to give your \(postType.lowercased()) a name!")
            return
        }
        
        var author = ""
        if let _user = UserController.Instance.getUser() as User? {
            author = _user.fullName
        }
        
        let fromPatientProfile = DataManager.Instance.getFromPatientProfile()
        if !fromPatientProfile {
            self.startIndicating()
        }
        
        var audioFilename: URL
        if (self.fileURL != nil) {
            audioFilename = self.fileURL!
        } else {
            audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        }
        
        let fileExtension = audioFilename.pathExtension
        let fileMimeType = fileExtension.mimeTypeForPathExtension()
        
        do {
            let audioData = try Data(contentsOf: audioFilename)
            
            if fromPatientProfile {
                // From Patient Profile
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "PatientNoteReferViewController") as? PatientNoteReferViewController {
                    
                    let noteInfo = ["title" : title,
                                    "author" : author,
                                    "description" : self.tvDescription.text!,
                                    "hashtags" : hashTagCtrl.tags as! [String],
                                    "postType" : postType,
                                    "audioData" : audioData,
                                    "fileExtension": fileExtension,
                                    "mimeType": fileMimeType] as [String : Any]
                    
                    vc.noteInfo = noteInfo
                    self.navigationController?.pushViewController(vc, animated: false)
                }
                
            } else {
                // From other screens
                self.btnSave.isEnabled = false
                
                PostService.Instance.sendPost(title, author: author, description: self.tvDescription.text!, hashtags: hashTagCtrl.tags as! [String], postType: postType, audioData: audioData, image: nil/*self.imgAvatar.image*/, fileExtension: fileExtension, mimeType: fileMimeType, completion: {
                    (success: Bool, postId: String?) in
                    
                    if success {
                        DispatchQueue.main.async {
                            self.stopIndicating()
                            self.btnSave.isEnabled = true
                            
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            if let vc = storyboard.instantiateViewController(withIdentifier: "ShareBroadcastViewController") as? ShareBroadcastViewController {
                                vc.postId = postId
                                self.navigationController?.pushViewController(vc, animated: false)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.stopIndicating()
                            self.btnSave.isEnabled = true
                        }
                    }
                })
            }
            
        } catch let error {
            if !fromPatientProfile {
                self.stopIndicating()
            }
            
            self.btnSave.isEnabled = true
            print(error.localizedDescription)
        }
        
    }
    
}
