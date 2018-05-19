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
import PDFKit

class SettingsDetailViewController: BaseViewController {

    var strTitle: String?
    var strSynopsisUrl: String?
    var destinationFileUrl: URL!
    var notes: String?
    var shouldSave: Bool = true
    
    let contentDict = ["Privacy Policy":"Privacy_policy_HTML", "Code of Conduct": "Code_of_conduct_HTML", "Terms of Use": "Terms_of_service_HTML"]
    
    private var _pdfDocument: Any?
    @available(iOS 11.0, *)
    fileprivate var pdfDocument: PDFDocument? {
        get {
            return _pdfDocument as? PDFDocument
        }
        set {
            _pdfDocument = newValue
        }
    }
    
    private var _pdfView: Any?
    @available(iOS 11.0, *)
    fileprivate var pdfView: PDFView? {
        get {
            return _pdfView as? PDFView
        }
        set {
            _pdfView = newValue
        }
    }
    
    @IBOutlet weak var m_lblTitle: UILabel!
    @IBOutlet weak var m_btnEdit: UIButton!
    @IBOutlet weak var m_btnShare: UIButton!
    @IBOutlet weak var m_contentWebView: UIWebView!
    @IBOutlet weak var m_pdfView: UIView!
    
    var activityIndicatorView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide Save button
        self.m_btnEdit.isHidden = true
        self.m_btnShare.isHidden = true
        
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
                self.m_pdfView.isHidden = true
                
                let url = Bundle.main.url(forResource: contentPath, withExtension: "html")
                let request = URLRequest(url: url!)
                self.m_contentWebView.loadRequest(request)
            }
        }
    }
    
    func downloadPDF(fileURL: URL) {
        // Create destination URL
        let documentsUrl: URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.destinationFileUrl = documentsUrl.appendingPathComponent("Synopsis.pdf") as URL?
        
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
                        self.stopIndicating()
                        
                        // Show PDF
                        if #available(iOS 11.0, *) {
                            self.m_contentWebView.isHidden = true
                            self.m_btnShare.isHidden = false
                            
                            if let _user = UserController.Instance.getUser() as User? {
                                if _user.isEditableTranscription(transcriptionUrl: self.strSynopsisUrl!) {
                                    self.m_btnEdit.isHidden = false
                                }
                            }
                            
                            if self.pdfView == nil {
                                self.pdfView = PDFView(frame: CGRect(x: 0, y: 0, width: self.m_pdfView.frame.width, height: self.m_pdfView.frame.height))
                                self.pdfView?.displayMode = PDFDisplayMode.singlePageContinuous
                                self.pdfView?.backgroundColor = UIColor.lightGray
                                self.m_pdfView.addSubview(self.pdfView!)
                            }
                            
                            self.pdfDocument = PDFDocument(url: self.destinationFileUrl!)
                            self.pdfView?.document = self.pdfDocument
//                            self.pdfView?.autoScales = true
                            self.pdfView?.maxScaleFactor = 4.0
                            self.pdfView?.minScaleFactor = (self.pdfView?.scaleFactorForSizeToFit)!
                            self.pdfView?.scaleFactor = (self.pdfView?.minScaleFactor)! + 0.18
                            
                            if let scrollView = self.pdfView?.subviews[0] as? UIScrollView {
                                scrollView.contentOffset = CGPoint.init(x: (scrollView.contentSize.width - scrollView.bounds.width) / 2, y: scrollView.contentOffset.y)
                            }
                            
                        } else {
                            // Fallback on earlier versions
                            self.m_pdfView.isHidden = true
                            
                            let request = URLRequest(url: self.destinationFileUrl)
                            self.m_contentWebView.loadRequest(request)
                        }
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
    
    private func getSubviewsOf<T: UIView>(view: UIView) -> [T] {
        var subviews = [T]()
        
        for subview in view.subviews {
            subviews += getSubviewsOf(view: subview) as [T]
            if String(describing: type(of: subview)) == "PDFPageView" {
                subviews.append((subview as? T)!)
            }
        }
        
        return subviews
    }
    
    // Mark : UI Actions
    @IBAction func btnBackClicked(_ sender: Any) {
        self.shouldSave = false
        self.view.endEditing(true)
        
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func btnEditClicked(_ sender: Any) {
        
        if #available(iOS 11.0, *) {
            if let page = self.pdfDocument?.page(at: 0) {
                let upperSelection = self.pdfDocument?.findString("Consult Notes:", withOptions: .literal)[0]
                let bottomSelection = self.pdfDocument?.findString("Consult Prepared by:", withOptions: .literal)[0]
                let upperBounds = upperSelection?.bounds(for: page)
                let bottomBounds = bottomSelection?.bounds(for: page)
                let pageBounds = page.bounds(for: .cropBox)
                
                var textFieldMultilineBounds = CGRect.zero
                if (bottomBounds?.size.height)! > CGFloat(0) {
                    textFieldMultilineBounds = CGRect(x: (upperBounds?.origin.x)! - 5, y: (pageBounds.size.height - (upperBounds?.origin.y)! + 4), width: (pageBounds.size.width - (upperBounds?.origin.x)! * 2 + 10), height: ((upperBounds?.origin.y)! - (bottomBounds?.origin.y)! - 25))
                } else {
                    textFieldMultilineBounds = CGRect(x: (upperBounds?.origin.x)! - 5, y: (pageBounds.size.height - (upperBounds?.origin.y)! + 4), width: (pageBounds.size.width - (upperBounds?.origin.x)! * 2 + 10), height: ((upperBounds?.origin.y)! - 80))
                }
                
                let textView: UITextView = UITextView.init(frame: textFieldMultilineBounds)
                textView.backgroundColor = UIColor.white
                textView.layer.borderColor = UIColor.gray.cgColor
                textView.layer.borderWidth = 1.0
                textView.layer.cornerRadius = 3.0
                textView.delegate = self
                
                if let text = self.pdfDocument?.string {
                    if let startRange = text.range(of: "Consult Notes:\n"),
                        let endRange = text.range(of: "\nConsult Prepared by:"),
                        startRange.upperBound < endRange.lowerBound {
                        let _notes = text[startRange.upperBound..<endRange.lowerBound]
                        print(text)
                        print(_notes)
                        self.notes = String(_notes)
                        textView.text = self.notes!
                    }
                }
                
                let allTextViews: [UIView] = self.getSubviewsOf(view: self.pdfView!)
                if allTextViews.count > 0 {
                    let _pageView = allTextViews[0]
                    _pageView.backgroundColor = UIColor.red
                    _pageView.addSubview(textView)
                    self.pdfView?.go(to: textFieldMultilineBounds, on: page)
                    textView.becomeFirstResponder()
                }
            }
        } else {
            // Fallback on earlier versions
            
        }
        
    }

    @IBAction func btnShareClicked(_ sender: UIButton) {
        // Present AlertController
        let alertController = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        let printAction = UIAlertAction.init(title: "PRINT", style: .default) { (action) in
            // Print
            if UIPrintInteractionController.canPrint(self.destinationFileUrl) {
                let printInfo = UIPrintInfo(dictionary: nil)
                printInfo.jobName = self.destinationFileUrl.lastPathComponent
                printInfo.outputType = .general
                
                let printController = UIPrintInteractionController.shared
                printController.printInfo = printInfo
                printController.showsNumberOfCopies = true
                printController.printingItem = self.destinationFileUrl
                
                printController.present(animated: true)
            } else {
                AlertUtil.showSimpleAlert(self, title: "Print service is not available.", message: nil, okButtonTitle: "OK")
            }
        }
        
        printAction.setValue(NSNumber(value: NSTextAlignment.left.rawValue), forKey: "titleTextAlignment")
        printAction.setValue(UIColor.init(red: 120/255.0, green: 120/255.0, blue: 120/255.0, alpha: 1), forKey: "titleTextColor")
        printAction.setValue(UIImage(named:"icon_print")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alertController.addAction(printAction)

        let submitMSPAction = UIAlertAction.init(title: "EMAIL", style: .default) { (action) in
            // Email
            if( MFMailComposeViewController.canSendMail()){
                print("Can send email.")
                
                DispatchQueue.main.async {
                    let mailComposer = MFMailComposeViewController()
                    mailComposer.mailComposeDelegate = self
                    
//                    mailComposer.setToRecipients(["yakupad@yandex.com"])
//                    mailComposer.setSubject("email with document pdf")
//                    mailComposer.setMessageBody("This is what they sound like.", isHTML: true)
                    
                    let pathPDF = self.destinationFileUrl.path
                    if let fileData = NSData(contentsOfFile: pathPDF) {
                        mailComposer.addAttachmentData(fileData as Data, mimeType: "application/pdf", fileName: self.destinationFileUrl.lastPathComponent)
                    }
                    
                    //this will compose and present mail to user
                    self.present(mailComposer, animated: true, completion: nil)
                }
            } else {
                print("email is not supported")
                AlertUtil.showSimpleAlert(self, title: "Mail services are not available.", message: nil, okButtonTitle: "OK")
            }
        }
        
        submitMSPAction.setValue(NSNumber(value: NSTextAlignment.left.rawValue), forKey: "titleTextAlignment")
        submitMSPAction.setValue(UIColor.init(red: 120/255.0, green: 120/255.0, blue: 120/255.0, alpha: 1), forKey: "titleTextColor")
        submitMSPAction.setValue(UIImage(named:"icon_submit")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        alertController.addAction(submitMSPAction)

        let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel)
        cancelAction.setValue(UIColor.init(red: 143/255.0, green: 195/255.0, blue: 196/255.0, alpha: 1), forKey: "titleTextColor")
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
        // Update AlertController Style
        
        let attributedText = NSMutableAttributedString(string: "SUBMIT TO MSP")
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.addAttribute(.font, value: UIFont(name: "Avenir-Medium", size: 15) ?? UIFont.systemFont(ofSize: 15), range: range)
        
        let actionViews = alertController.view.value(forKey: "actionViews") as! [UIView]
        if actionViews.count > 0 {
            let printView = actionViews[0] as UIView
//            (printView.value(forKey: "label") as! UILabel).attributedText = attributedText
            (printView.value(forKey: "marginToImageConstraint") as! NSLayoutConstraint).constant = Constants.ScreenWidth - 84
            
            let submitMSPView = actionViews[1] as UIView
//            (submitMSPView.value(forKey: "label") as! UILabel).font = UIFont(name: "Avenir-Medium", size: 15) ?? UIFont.systemFont(ofSize: 15)
            (submitMSPView.value(forKey: "marginToImageConstraint") as! NSLayoutConstraint).constant = Constants.ScreenWidth - 80
        }
        
    }
    
    // MARK: Activity Indicator
    
    func startIndicating(){
        activityIndicatorView.center = self.view.center
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.activityIndicatorViewStyle = .gray
        view.addSubview(activityIndicatorView)
        
        activityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func stopIndicating() {
        if activityIndicatorView.superview != nil {
            activityIndicatorView.stopAnimating()
            activityIndicatorView.removeFromSuperview()
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }
    
}

extension SettingsDetailViewController : UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.shouldSave = true
        self.m_btnEdit.isHidden = true
        self.m_btnShare.isHidden = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let _notes = textView.text,
            _notes != self.notes,
            self.shouldSave == true {
            // Notes updated
            self.startIndicating()
            PostService.Instance.updateTranscript(transcriptionURL: self.strSynopsisUrl!, notes: _notes) { (success) in
                if success {
                    if let synopsisUrl = self.strSynopsisUrl as String? {
                        self.downloadPDF(fileURL: URL(string: synopsisUrl)!)
                    }
                } else {
                    self.stopIndicating()
                    self.m_btnEdit.isHidden = false
                    self.m_btnShare.isHidden = false
                    
                    AlertUtil.showSimpleAlert(self, title: "You cannot edit the transcription now. Please try again.", message: nil, okButtonTitle: "OK")
                }
            }
        } else {
            self.m_btnEdit.isHidden = false
            self.m_btnShare.isHidden = false
        }
        
        textView.removeFromSuperview()
    }
    
}

extension SettingsDetailViewController : UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url?.absoluteString {
            if url == "https://www.codiapp.com/privacy" {
                self.strTitle = "Privacy Policy"
                openContents()
            } else if url == "https://www.codiapp.com/conduct" {
                self.strTitle = "Code of Conduct"
                openContents()
            } else if url == "https://www.codiapp.com/support" {
                self.sendEmail(subject: "Contact Us", msgbody: "")
            }
        }
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if (self.strSynopsisUrl as String?) != nil {
            // Synopsis Document
//            self.m_btnEdit.isHidden = false
            self.m_btnShare.isHidden = false
            
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
        mailComposer.setToRecipients(["info@codiapp.com"])
        mailComposer.setSubject( subject )
        mailComposer.setMessageBody(msgbody, isHTML: false)
        
        present(mailComposer, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
}

extension UIWebView {
    
    open override var safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
}
