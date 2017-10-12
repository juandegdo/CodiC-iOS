//
//  RecordPopupViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-11.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class RecordPopupViewController: BaseViewController {
    
    @IBOutlet var mBackgroundImageView: UIImageView!
    @IBOutlet var btnUpload: UIButton!
    @IBOutlet var btnRecord: UIButton!
    
    var isDiagnosis: Bool = true
    
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
        
        if isDiagnosis {
            self.btnRecord.setTitle("record diagnosis", for: .normal)
            self.btnRecord.setImage(#imageLiteral(resourceName: "icon_record_diagnosis_highlighted"), for: .normal)
            self.btnUpload.setTitle("upload diagnosis", for: .normal)
            
        } else {
            self.btnRecord.setTitle("record new note", for: .normal)
            self.btnRecord.setImage(#imageLiteral(resourceName: "icon_record_note_highlighted"), for: .normal)
            self.btnUpload.setTitle("upload new note", for: .normal)
            
        }
        
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
    
    @IBAction func onRecord(sender: UIButton!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
            self.present(vc, animated: false, completion: nil)
        }
        
        self.onClose(sender: nil)
    }
    
    @IBAction func onUpload(sender: UIButton!) {
        
    }
    
}
