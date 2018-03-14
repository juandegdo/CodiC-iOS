//
//  CallScreenViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2018-03-12.
//  Copyright © 2018 Loewen. All rights reserved.
//

import UIKit

class CallScreenViewController: UIViewController, SINCallClientDelegate, SINCallDelegate {

    @IBOutlet weak var ivProfileImage: UIImageView!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var btnDecline: UIButton!
    @IBOutlet weak var btnAccept: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    
    var call: SINCall? = nil {
        didSet {
            call?.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.lblDescription.text = "Call from Ming..."
        self.btnCancel.isHidden = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - SINCallDelegate
    
    func callDidEstablish(_ call: SINCall!) {
        self.lblDescription.text = ""
    }
    
    func callDidEnd(_ call: SINCall!) {
        self.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CallScreenViewController {
    
    // MARK: - IBActions
    
    @IBAction func onDecline(sender: AnyObject) {
        self.call?.hangup()
    }
    
    @IBAction func onAccept(sender: AnyObject) {
        self.call?.answer()
        self.lblDescription.text = ""
        self.btnDecline.isHidden = true
        self.btnAccept.isHidden = true
        self.btnCancel.isHidden = false
    }
    
}
