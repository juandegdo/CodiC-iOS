//
//  RecordPopupViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-11.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import MobileCoreServices

class RecordPopupViewController: BaseViewController {
    
    @IBOutlet var mBackgroundImageView: UIImageView!
    @IBOutlet var btnRecordConsult: UIButton!
    @IBOutlet var btnRecordDiagnosis: UIButton!
    
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
    
    //MARK: Initialize Views
    
    func initViews() {
        // Background captured image
        self.mBackgroundImageView.image = ImageHelper.captureView()
        
    }
    
}

extension RecordPopupViewController {
    //MARK: IBActions
    
    @IBAction func onClose(sender: UIButton!) {
        if let _nav = self.navigationController as UINavigationController? {
            _ = _nav.popViewController(animated: false)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func onRecordDiagnosis(sender: UIButton!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
            
            DataManager.Instance.setPostType(postType: Constants.PostTypeDiagnosis)
            DataManager.Instance.setPatientId(patientId: "")
            DataManager.Instance.setReferringUserIds(referringUserIds: [])
            
            weak var weakSelf = self
            self.present(vc, animated: false, completion: {
                weakSelf?.onClose(sender: nil)
            })
            
        }
    }
    
    @IBAction func onRecordConsult(sender: UIButton!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "ConsultReferringViewController") as? ConsultReferringViewController {
            
            self.navigationController?.pushViewController(vc, animated: true)
            
        }
    }
    
}
