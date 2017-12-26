//
//  SettingsDetailViewController.swift
//  MedicConnect
//
//  Created by Voltae Saito on 7/1/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import MessageUI

class SettingsDetailViewController: UIViewController {

    var strTitle: String?
    
    let contentDict = ["Privacy Policy":"Privacy_policy_HTML", "Code of Conduct": "Code_of_conduct_HTML", "Terms of Use": "Terms_of_service_HTML"]
    
    @IBOutlet weak var m_lblTitle: UILabel!
    @IBOutlet weak var m_contentWebView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        openContents()
    }
    
    func openContents(){
        if let titleText = strTitle {
            self.m_lblTitle.text = titleText
            
            if let contentPath = contentDict[titleText] {
                let url = Bundle.main.url(forResource: contentPath, withExtension: "html")
                let request = URLRequest(url: url!)
                self.m_contentWebView.loadRequest(request)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    // Mark : UI Actions
    @IBAction func btnBackClicked(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }

}

extension SettingsDetailViewController : UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url?.absoluteString {
            if url == "https://www.medicconnect.com/privacy" {
                self.strTitle = "Privacy Policy"
                openContents()
            } else if url == "https://www.medicconnect.com/conduct" {
                self.strTitle = "Code of Conduct"
                openContents()
            } else if url == "https://www.medicconnect.com/support" {
                self.sendEmail(subject: "Contact Us", msgbody: "")
            }
        }
        return true
    }
}


extension SettingsDetailViewController : MFMailComposeViewControllerDelegate {
    func sendEmail(subject: String, msgbody: String){
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients(["info@medicconnect.com"])
        mailComposer.setSubject( subject )
        mailComposer.setMessageBody(msgbody, isHTML: false)
        
        present(mailComposer, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
}
