//
//  SettingsDetailViewController.swift
//  MedicConnect
//
//  Created by Voltae Saito on 7/1/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit
import MessageUI
import MobileCoreServices

class SettingsDetailViewController: UIViewController {

    var strTitle: String?
    var strSynopsisUrl: String?
    
    let contentDict = ["Privacy Policy":"Privacy_policy_HTML", "Code of Conduct": "Code_of_conduct_HTML", "Terms of Use": "Terms_of_service_HTML"]
    
    var destinationFileUrl: URL!
    
    @IBOutlet weak var m_lblTitle: UILabel!
    @IBOutlet weak var m_btnSave: UIButton!
    @IBOutlet weak var m_contentWebView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide Save button
        self.m_btnSave.isHidden = true
        
        openContents()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // Mark : Private Methods
    
    func openContents() {
        if let titleText = strTitle {
            self.m_lblTitle.text = titleText
            
            if let synopsisUrl = self.strSynopsisUrl as String? {
                self.downloadPDF(fileURL: URL(string: synopsisUrl)!)
                
            } else if let contentPath = contentDict[titleText] {
                let url = Bundle.main.url(forResource: contentPath, withExtension: "html")
                let request = URLRequest(url: url!)
                self.m_contentWebView.loadRequest(request)
            }
        }
    }
    
    func downloadPDF(fileURL: URL) {
        // Create destination URL
        let documentsUrl: URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        self.destinationFileUrl = documentsUrl.appendingPathComponent("Synopsis.pdf") as URL!
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let request = URLRequest(url:fileURL)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Successfully downloaded. Status code: \(statusCode)")
                }
                
                do {
                    if FileManager.default.fileExists(atPath: self.destinationFileUrl.path) {
                        try FileManager.default.removeItem(at: self.destinationFileUrl)
                    }
                    
                    try FileManager.default.copyItem(at: tempLocalUrl, to: self.destinationFileUrl)
                    
                    DispatchQueue.main.async {
                        // Show PDF
                        let request = URLRequest(url: self.destinationFileUrl)
                        self.m_contentWebView.loadRequest(request)
                    }
                    
                } catch (let writeError) {
                    print("Error creating a file \(self.destinationFileUrl) : \(writeError)")
                }
                
            } else {
                print("Error took place while downloading a file. Error description: %@", error?.localizedDescription as Any);
            }
        }
        task.resume()
    }
    
    // Mark : UI Actions
    @IBAction func btnBackClicked(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }

    @IBAction func btnSaveClicked(_ sender: UIButton) {
        // Present AlertController
//        let alertController = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
//        let printAction = UIAlertAction.init(title: "Print", style: .default) { (action) in
//
//        }
//        alertController.addAction(printAction)
//
//        let submitMSPAction = UIAlertAction.init(title: "Submit to MSP", style: .default) { (action) in
//
//        }
//        alertController.addAction(submitMSPAction)
//
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
//        alertController.addAction(cancelAction)
//
//        self.present(alertController, animated: true, completion: nil)
        
        let documento = NSData.init(contentsOf: self.destinationFileUrl)
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [documento!], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        if #available(iOS 11.0, *) {
            activityViewController.excludedActivityTypes = [
                UIActivityType.airDrop,
                UIActivityType.message,
                UIActivityType.mail,
                UIActivityType.copyToPasteboard,
                UIActivityType.markupAsPDF,
                UIActivityType(rawValue: "com.apple.reminders.RemindersEditorExtension"),
                UIActivityType(rawValue: "com.apple.mobilenotes.SharingExtension"),
            ]
        } else {
            // Fallback on earlier versions
            activityViewController.excludedActivityTypes = [
                UIActivityType.airDrop,
                UIActivityType.message,
                UIActivityType.mail,
                UIActivityType.copyToPasteboard,
                UIActivityType(rawValue: "com.apple.reminders.RemindersEditorExtension"),
                UIActivityType(rawValue: "com.apple.mobilenotes.SharingExtension"),
            ]
        }
        
        self.present(activityViewController, animated: true, completion: nil)
        
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
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if (self.strSynopsisUrl as String?) != nil {
            // Synopsis Document
            self.m_btnSave.isHidden = false
            
            // Enable zoom
            self.m_contentWebView.scrollView.minimumZoomScale = 1.0
            self.m_contentWebView.scrollView.maximumZoomScale = 5.0
        }
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
