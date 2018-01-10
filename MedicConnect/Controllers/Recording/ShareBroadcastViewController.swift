//
//  ShareBroadcastViewController.swift
//  MedicConnect
//
//  Created by alessandro on 12/5/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit

class ShareBroadcastViewController: BaseViewController {
    
    @IBOutlet var mBackgroundImageView: UIImageView!
    @IBOutlet var lblDescription: UILabel!
    @IBOutlet var lblQuestion: UILabel!
    
    @IBOutlet var btnEmail: UIButton!
    @IBOutlet var btnMessage: UIButton!
    @IBOutlet var btnDocument: UIButton!
    
    @IBOutlet var btnSkip: UIButton!
    @IBOutlet var btnYes: UIButton!
    @IBOutlet var viewYes: UIView!
    
    var postId: String?
    
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
    
    func initViews() {
        
        // Background captured image
        self.mBackgroundImageView.image = ImageHelper.captureView()
        
        // Record Description
        self.lblDescription.text = "You’ve successfully\nrecorded a new \(DataManager.Instance.getPostType().lowercased())."
        
        if (DataManager.Instance.getPostType() == Constants.PostTypeDiagnosis) {
            // Diagnosis
            self.lblQuestion.text = "Would you like to share it?"
            self.btnDocument.isHidden = true
            self.viewYes.isHidden = true
            
        } else {
            // Consult or Patient Note
            self.lblQuestion.text = "Would you like to create\na synopsis document?"
            self.btnEmail.isHidden = true
            self.btnMessage.isHidden = true
            
        }
        
        // Buttons highlighted status
        self.btnSkip.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
        self.btnYes.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
    
    }
}

extension ShareBroadcastViewController {
    //MARK: IBActions
    
    @IBAction func onClose(sender: UIButton) {
        if let _nav = self.navigationController as UINavigationController? {
            _nav.dismiss(animated: false, completion: nil)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func onSocialButtonSelect(sender: UIButton!) {
        
        sender.isSelected = !sender.isSelected
        
    }
    
    @IBAction func onSkip(sender: UIButton) {
        if (DataManager.Instance.getPostType() == Constants.PostTypeDiagnosis) {
            // Diagnosis
            self.onClose(sender: sender)
        } else {
            // Consult or Patient Note
//            self.btnSkip.isEnabled = false
//            self.btnYes.isEnabled = false
//
//            UserService.Instance.getMe(completion: {
//                (user: User?) in
//                DispatchQueue.main.async {
//                    self.onClose(sender: sender)
//                }
//            })
            
            self.onClose(sender: sender)
        }
    }
    
    @IBAction func onYes(sender: UIButton) {
        if (DataManager.Instance.getPostType() == Constants.PostTypeDiagnosis) {
            // Diagnosis
            self.onClose(sender: sender)
        } else {
            // Consult or Patient Note
            self.btnSkip.isEnabled = false
            self.btnYes.isEnabled = false
            
            PostService.Instance.placeOrder(postId: self.postId!, completion: { (success: Bool) in
                
                if success {
                    UserService.Instance.getMe(completion: {
                        (user: User?) in
                        DispatchQueue.main.async {
                            self.onClose(sender: sender)
                        }
                    })
                    
                } else {
                    DispatchQueue.main.async {
                        self.btnSkip.isEnabled = true
                        self.btnYes.isEnabled = true
                    }
                }
                
            })
        }
    }

}
