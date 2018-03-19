//
//  ConferenceViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-10-31.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class ConferenceViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViews()
        
    }
    
    //MARK: UI Functions
    
    func initViews() {
        
    }
    
    @IBAction func onShowCallScreen(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if  let vc = storyboard.instantiateViewController(withIdentifier: "CallScreenViewController") as? CallScreenViewController {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let vvc = appDelegate.window?.visibleViewController() {
                vvc.present(vc, animated: false, completion: nil)
            }
        }
    }
    
}
