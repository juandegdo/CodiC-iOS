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
    
    var fileURL: URL?
    
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
    
    //MARK: Private Methods
    func uploadFile(_ url: URL) {
        self.fileURL = url
        
        let destinationVC = self.storyboard!.instantiateViewController(withIdentifier: "saveBroadcastVC") as! SaveBroadcastViewController
        destinationVC.fileURL = self.fileURL
        self.navigationController?.pushViewController(destinationVC, animated: true)
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
            
            DataManager.Instance.setPostType(postType: "Diagnosis")
            
            weak var weakSelf = self
            self.present(vc, animated: false, completion: {
                weakSelf?.onClose(sender: nil)
            })
            
        }
    }
    
    @IBAction func onRecordConsult(sender: UIButton!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
            
            DataManager.Instance.setPostType(postType: "Consult")
            
            weak var weakSelf = self
            self.present(vc, animated: false, completion: {
                weakSelf?.onClose(sender: nil)
            })
            
        }
    }
    
    @IBAction func onUpload(sender: UIButton!) {
        let importMenu = UIDocumentMenuViewController(documentTypes: [kUTTypeAudio as String], in: .import)
        importMenu.delegate = self
        importMenu.popoverPresentationController?.sourceView = sender
        self.present(importMenu, animated: true, completion: nil)
    }
    
}

//MARK: - UIDocumentMenuDelegate
extension RecordPopupViewController: UIDocumentMenuDelegate {
    
    public func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        print("document pick")
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    public func documentMenuWasCancelled(_ documentMenu: UIDocumentMenuViewController) {
        print("document menu cancelled")
    }
    
}

//MARK: - UIDocumentPickerDelegate
extension RecordPopupViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.uploadFile(url)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("document picker cancelled")
    }
    
}
