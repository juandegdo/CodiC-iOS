//
//  ErrorPopupViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-12-20.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

public enum ErrorPopupType {
    case none
    case noMSP
    case noPHN
    case noMSPAndPHN
}

class ErrorPopupViewController: BaseViewController {
    
    @IBOutlet var mBackgroundImageView: UIImageView!
    @IBOutlet var lblDescription: UILabel!
    @IBOutlet var lblQuestion: UILabel!
    
    @IBOutlet var btnNo: UIButton!
    @IBOutlet var btnYes: UIButton!
    @IBOutlet var viewYes: UIView!
    
    @IBOutlet var constOfViewHeight: NSLayoutConstraint!
    
    var popupType: ErrorPopupType = .none
    var isYes: Bool = false
    
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
        
        switch (self.popupType) {
        case .noMSP:
            self.constOfViewHeight.constant = 212.0
            self.lblDescription.text = "You didn't enter correct Doctor's MSP"
            self.lblQuestion.text = "Would you like to\ncontinue without associating this\nconsult with a referring doctor?"
            break
            
        case .noPHN:
            self.constOfViewHeight.constant = 212.0
            self.lblDescription.text = "You didn't enter correct Patient's PHN"
            self.lblQuestion.text = "Would you like to\ncontinue without associating this\nconsult with a patient?"
            break
            
        case .noMSPAndPHN:
            self.constOfViewHeight.constant = 244.0
            self.lblDescription.text = "You didn't enter correct Patient's PHN\nor Doctor's MSP"
            self.lblQuestion.text = "Would you like to\ncontinue without associating this\nconsult with a patient or\nreferring doctor?"
            break
            
        default:
            break
        }
        
        // Buttons highlighted status
        self.btnNo.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
        self.btnYes.setBackgroundColor(color: UIColor.init(red: 146/255.0, green: 153/255.0, blue: 157/255.0, alpha: 1.0), forState: .highlighted)
        
    }
    
    func close() {
        if let _nav = self.navigationController as UINavigationController? {
            if isYes == true {
                _nav.popToRootViewController(animated: false)
            } else {
                _nav.popViewController(animated: false)
            }
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
}

extension ErrorPopupViewController {
    //MARK: IBActions
    
    @IBAction func onClose(sender: UIButton!) {
        self.isYes = false
        self.close()
    }
    
    @IBAction func onNo(sender: UIButton) {
        self.isYes = false
        self.close()
    }
    
    @IBAction func onYes(sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "recordNavController") as? UINavigationController {
            
            weak var weakSelf = self
            self.present(vc, animated: false, completion: {
                weakSelf?.isYes = true
                weakSelf?.close()
            })
            
        }
    }
    
}
