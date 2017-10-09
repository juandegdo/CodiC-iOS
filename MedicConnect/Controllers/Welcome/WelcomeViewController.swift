//
//  WelcomeViewController.swift
//  MedicConnect
//
//  Created by alessandro on 2/23/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class WelcomeViewController: BaseViewController {
    
    @IBOutlet var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
    }
    
    // MARK: Initialize Views
    
    func initViews() {
        
        // Page Control
        self.pageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
    }
    
    func callWelcomeProfileVC() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "WelcomeProfileVC") as? WelcomeProfileViewController {
            self.navigationController?.pushViewController(vc, animated: false)
        }
        
    }
    
    @IBAction func tapSignup(_ sender: Any) {
        
        self.performSegue(withIdentifier: Constants.SegueMedicConnectSignup, sender: nil)
        
    }
    
}
