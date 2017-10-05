//
//  WelcomeLastViewController.swift
//  Radioish
//
//  Created by alessandro on 2/23/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class WelcomeLastViewController: BaseViewController {
    
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
    
    @IBAction func tapLetsStart(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: false)
    }
    
}
