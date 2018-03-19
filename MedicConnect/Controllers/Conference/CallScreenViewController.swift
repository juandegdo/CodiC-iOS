//
//  CallScreenViewController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2018-03-12.
//  Copyright © 2018 Loewen. All rights reserved.
//

import UIKit
import FXBlurView

enum EButtonsBar {
    case kButtonsAnswerDecline
    case kButtonsHangup
}

class CallScreenViewController: UIViewController, SINCallClientDelegate, SINCallDelegate {
    
    @IBOutlet weak var mBackgroundImageView: UIImageView!
    @IBOutlet weak var blurView: FXBlurView!
    @IBOutlet weak var maskView: UIView!
    
    @IBOutlet weak var lblRemoteUserName: UILabel!
    @IBOutlet weak var lblRemoteUserLocation: UILabel!
    @IBOutlet weak var lblCallState: UILabel!
    
    // Buttons
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnSwitchCamera: UIButton!
    @IBOutlet weak var btnAccept: UIButton!
    @IBOutlet weak var btnEnd: UIButton!
    @IBOutlet weak var btnSpeaker: UIButton!
    @IBOutlet weak var btnMute: UIButton!
    
    // Video Views
    @IBOutlet weak var viewLocalContainer: UIView!
    @IBOutlet weak var viewLocalVideo: UIView!
    @IBOutlet weak var viewRemoteVideo: UIView!
    
    var durationTimer: Timer?
    var speakerEnabled: Bool = false
    var muted: Bool = false
    
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
        
        self.initViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.audioController?.enableSpeaker()
        self.audioController?.unmute()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Initialize views
    
    func initViews() {
        // Background captured image
        self.mBackgroundImageView.image = ImageHelper.captureView()
        
        // Customize Avatar
        if let _user = UserController.Instance.findUserById((self.call?.remoteUserId)!) {
            self.lblRemoteUserName.text = _user.fullName
            self.lblRemoteUserLocation.text = _user.location
        }
        
        self.setCallStatusText("CALLING...")
        self.showButtons(.kButtonsAnswerDecline)
        self.audioController?.startPlayingSoundFile(self.pathForSound("incoming.wav"), loop: true)
        
        self.viewLocalVideo.layer.borderColor = UIColor.init(red: 147/255.0, green: 203/255.0, blue: 202/255.0, alpha: 1.0).cgColor
        
    }
    
    // MARK: Private Methods
    
    func pathForSound(_ soundName: String) -> String {
        return Bundle.main.resourceURL!.appendingPathComponent(soundName).path
    }
    
    @objc func onDurationTimer(_ unused: Timer) {
        let duration: Int = Int(Date().timeIntervalSince((self.call?.details.establishedTime)!))
        self.setDuration(duration)
    }
    
    // MARK: - SINCallDelegate
    
    func callDidProgress(_ call: SINCall!) {
        self.setCallStatusText("CALLING...")
        self.audioController?.startPlayingSoundFile(self.pathForSound("ringback.wav"), loop: true)
    }
    
    func callDidEstablish(_ call: SINCall!) {
        self.audioController?.disableSpeaker()
        
        if self.call?.details.isVideoOffered == false {
            self.startCallDurationTimerWithSelector(#selector(onDurationTimer(_:)))
        }
        
        self.showButtons(.kButtonsHangup)
        self.audioController?.stopPlayingSoundFile()
    }
    
    func callDidEnd(_ call: SINCall!) {
        self.audioController?.stopPlayingSoundFile()
        self.audioController?.disableSpeaker()
        self.stopCallDurationTimer()
        
        if (self.call?.details.isVideoOffered)! {
            self.videoController?.remoteView().removeFromSuperview()
        }
        
        self.dismiss(animated: true, completion: nil)
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
            self.viewLocalContainer.isHidden = true
            self.viewRemoteVideo.isHidden = true
            
            self.btnSwitchCamera.isHidden = true
            self.btnSpeaker.isHidden = true
            self.btnMute.isHidden = true
            self.btnEnd.isHidden = true
        } else if buttons == .kButtonsHangup {
            if (self.call?.details.isVideoOffered)! {
                // Video Call
                self.videoController?.localView().contentMode = .scaleAspectFill
                self.viewLocalVideo.addSubview((self.videoController?.localView())!)
                
                self.viewLocalContainer.isHidden = false
                self.viewRemoteVideo.isHidden = false
                self.btnSwitchCamera.isHidden = false
                
                self.viewRemoteVideo.backgroundColor = UIColor.black
                
                self.mBackgroundImageView.isHidden = true
                self.blurView.isHidden = true
                self.maskView.isHidden = true
                
                self.lblRemoteUserName.isHidden = true
                self.lblRemoteUserLocation.isHidden = true
                self.lblCallState.isHidden = true
                
            } else {
                
            }
            
            self.btnClose.isHidden = true
            self.btnAccept.isHidden = true
            self.btnSpeaker.isHidden = false
            self.btnMute.isHidden = false
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
        if (self.durationTimer != nil) {
            self.durationTimer?.invalidate()
            self.durationTimer = nil
        }
    }
    
}

extension CallScreenViewController {
    
    // MARK: - IBActions
    
    @IBAction func onClose(sender: AnyObject) {
        self.call?.hangup()
    }
    
    @IBAction func onSwitchCamera(sender: AnyObject) {
        self.videoController?.captureDevicePosition = SINToggleCaptureDevicePosition((self.videoController?.captureDevicePosition)!);
    }
    
    @IBAction func onAccept(sender: AnyObject) {
        self.audioController?.stopPlayingSoundFile()
        self.call?.answer()
    }
    
    @IBAction func onSpeaker(sender: AnyObject) {
        if self.speakerEnabled {
            self.btnSpeaker.setImage(UIImage(named: "icon_call_speaker"), for: .normal)
            self.audioController?.disableSpeaker()
        } else {
            self.btnSpeaker.setImage(UIImage(named: "icon_call_speaker_on"), for: .normal)
            self.audioController?.enableSpeaker()
        }
        
        self.speakerEnabled = !self.speakerEnabled
    }
    
    @IBAction func onMute(sender: AnyObject) {
        if self.muted {
            self.btnMute.setImage(UIImage(named: "icon_mute"), for: .normal)
            self.audioController?.unmute()
        } else {
            self.btnMute.setImage(UIImage(named: "icon_muted"), for: .normal)
            self.audioController?.mute()
        }
        
        self.muted = !self.muted
    }
    
    @IBAction func onEndCall(sender: AnyObject) {
        self.call?.hangup()
    }
    
}
