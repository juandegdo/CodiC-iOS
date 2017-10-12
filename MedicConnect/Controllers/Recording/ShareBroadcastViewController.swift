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
    @IBOutlet var btnFacebook: UIButton!
    @IBOutlet var btnTwitter: UIButton!
    @IBOutlet var btnEmail: UIButton!
    @IBOutlet var btnMessage: UIButton!
    @IBOutlet var btnOK: UIButton!
    
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
        
        // OK button highlighted status
        self.btnOK.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
    
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
    
    @IBAction func onOK(sender: UIButton) {
        self.onClose(sender: sender)
    }

}
