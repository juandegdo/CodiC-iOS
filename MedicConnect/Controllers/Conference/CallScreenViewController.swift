//
//  CallScreenViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2018-03-12.
//  Copyright © 2018 Loewen. All rights reserved.
//

import UIKit

enum EButtonsBar {
    case kButtonsAnswerDecline
    case kButtonsHangup
}

class CallScreenViewController: UIViewController, SINCallClientDelegate, SINCallDelegate {
    
    @IBOutlet weak var lblRemoteUserName: UILabel!
    @IBOutlet weak var lblCallState: UILabel!
    
    @IBOutlet weak var ivRemoteUser: UIImageView!
    
    @IBOutlet weak var viewLocalVideo: UIView!
    @IBOutlet weak var viewRemoteVideo: UIView!
    
    @IBOutlet weak var btnEnd: UIButton!
    @IBOutlet weak var btnAccept: UIButton!
    @IBOutlet weak var btnDecline: UIButton!
    
    var durationTimer: Timer?
    
    var audioController: SINAudioController? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.sinchClient?.audioController()
    }
    
    var videoController: SINVideoController? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.sinchClient?.videoController()
    }
    
    var call: SINCall? = nil {
        didSet {
            call?.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setCallStatusText("")
        self.showButtons(.kButtonsAnswerDecline)
        self.audioController?.startPlayingSoundFile(self.pathForSound("incoming.wav"), loop: true)
        
        if (self.call?.details.isVideoOffered)! {
            // Video Call
            self.videoController?.localView().contentMode = .scaleAspectFill
            self.viewLocalVideo.addSubview((self.videoController?.localView())!)
            
            self.ivRemoteUser.isHidden = true
            self.viewLocalVideo.isHidden = false
            self.viewRemoteVideo.isHidden = false
            
//            [self.localVideoFullscreenGestureRecognizer requireGestureRecognizerToFail:self.switchCameraGestureRecognizer];
//            [[[self videoController] localView] addGestureRecognizer:self.localVideoFullscreenGestureRecognizer];
//            [[[self videoController] remoteView] addGestureRecognizer:self.remoteVideoFullscreenGestureRecognizer];
            
        } else {
            // Audio Call
            self.ivRemoteUser.isHidden = false
            self.viewLocalVideo.isHidden = true
            self.viewRemoteVideo.isHidden = true
            
            // Customize Avatar
            if let _user = UserController.Instance.findUserById((self.call?.remoteUserId)!) {
                self.lblRemoteUserName.text = _user.fullName
                
                if let imgURL = URL(string: _user.photo) as URL? {
                    self.ivRemoteUser.af_setImage(withURL: imgURL)
                } else {
                    self.ivRemoteUser.image = ImageHelper.circleImageWithBackgroundColorAndText(backgroundColor: UIColor.init(red: 185/255.0, green: 186/255.0, blue: 189/255.0, alpha: 1.0),
                                                                                                text: _user.getInitials(),
                                                                                                font: UIFont(name: "Avenir-Book", size: 44)!,
                                                                                                size: CGSize(width: 98, height: 98))
                }
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.lblRemoteUserName.text = "Daniel"
        self.audioController?.enableSpeaker()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pathForSound(_ soundName: String) -> String {
        return Bundle.main.resourceURL!.appendingPathComponent(soundName).path
    }
    
    @objc func onDurationTimer(_ unused: Timer) {
        let duration: Int = Int(Date().timeIntervalSince((self.call?.details.establishedTime)!))
        self.setDuration(duration)
    }
    
    // MARK: - SINCallDelegate
    
    func callDidProgress(_ call: SINCall!) {
        self.setCallStatusText("ringing...")
        self.audioController?.startPlayingSoundFile(self.pathForSound("ringback.wav"), loop: true)
    }
    
    func callDidEstablish(_ call: SINCall!) {
        self.startCallDurationTimerWithSelector(#selector(onDurationTimer(_:)))
        self.showButtons(.kButtonsHangup)
        self.audioController?.stopPlayingSoundFile()
    }
    
    func callDidEnd(_ call: SINCall!) {
        self.dismiss(animated: true, completion: nil)
        
        self.audioController?.stopPlayingSoundFile()
        self.audioController?.disableSpeaker()
        self.stopCallDurationTimer()
        
        if (self.call?.details.isVideoOffered)! {
            self.videoController?.remoteView().removeFromSuperview()
        }
    }
    
    func callDidAddVideoTrack(_ call: SINCall!) {
        self.videoController?.remoteView().contentMode = .scaleAspectFill
        self.viewRemoteVideo.addSubview((self.videoController?.remoteView())!)
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
    
    // MARK: - UI Methods
    
    fileprivate func setCallStatusText(_ text: String) {
        self.lblCallState.text = text
    }
    
    fileprivate func showButtons(_ buttons: EButtonsBar) {
        if buttons == .kButtonsAnswerDecline {
            self.btnAccept.isHidden = false
            self.btnDecline.isHidden = false
            self.btnEnd.isHidden = true
        } else if buttons == .kButtonsHangup {
            self.btnAccept.isHidden = true
            self.btnDecline.isHidden = true
            self.btnEnd.isHidden = false
        }
    }
    
    fileprivate func setDuration(_ seconds: Int) {
        self.setCallStatusText(String.init(format: "%02d:%02d", arguments: [Int(seconds / 60), Int(seconds % 60)]))
    }
    
    @objc fileprivate func internal_updateDuration(_ timer: Timer) {
        let selector: Selector = NSSelectorFromString(timer.userInfo as! String)
        if self.responds(to: selector) {
            self.perform(selector, with: timer)
        }
    }
    
    fileprivate func startCallDurationTimerWithSelector(_ sel: Selector) {
        let selectorAsString: String = NSStringFromSelector(sel)
        self.durationTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                                  target: self,
                                                  selector: #selector(internal_updateDuration(_:)),
                                                  userInfo: selectorAsString,
                                                  repeats: true)
    }
    
    fileprivate func stopCallDurationTimer() {
        self.durationTimer?.invalidate()
        self.durationTimer = nil
    }
    
}

extension CallScreenViewController {
    
    // MARK: - IBActions
    
    @IBAction func onEndCall(sender: AnyObject) {
        self.call?.hangup()
    }
    
    @IBAction func onDecline(sender: AnyObject) {
        self.call?.hangup()
    }
    
    @IBAction func onAccept(sender: AnyObject) {
        self.audioController?.stopPlayingSoundFile()
        self.call?.answer()
    }
    
}
