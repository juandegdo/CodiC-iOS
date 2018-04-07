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
    
    // Local Video Constraints
    @IBOutlet weak var constOfLocalContainerLeading: NSLayoutConstraint!
    @IBOutlet weak var constOfLocalContainerTop: NSLayoutConstraint!
    @IBOutlet weak var constOfLocalContainerTrailing: NSLayoutConstraint!
    @IBOutlet weak var constOfLocalContainerBottom: NSLayoutConstraint!
    
    @IBOutlet weak var constOfLocalVideoLeading: NSLayoutConstraint!
    @IBOutlet weak var constOfLocalVideoTrailing: NSLayoutConstraint!
    @IBOutlet weak var constOfLocalVideoTop: NSLayoutConstraint!
    @IBOutlet weak var constOfLocalVideoBottom: NSLayoutConstraint!
    
    var fromCallKit: Bool = false
    
    private var durationTimer: Timer?
    private var speakerEnabled: Bool = false
    private var muted: Bool = false
    
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
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        let currentRoute = AVAudioSession.sharedInstance().currentRoute
//        var hasHeadphones = false
//        for description in currentRoute.outputs {
//            if description.portType == AVAudioSessionPortHeadphones {
//                hasHeadphones = true
//                break
//            }
//        }
//
//        if !hasHeadphones {
//            self.audioController?.enableSpeaker()
//        } else {
//            self.audioController?.disableSpeaker()
//        }
        
//        self.speakerEnabled = !(self.call?.details.isVideoOffered)!
//        self.onSpeaker(sender: self.btnSpeaker)
        
        self.audioController?.enableSpeaker()
        self.audioController?.unmute()
        
        self.initViews()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.call?.details.isVideoOffered == true {
            AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        }
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
        
        if self.fromCallKit || self.call?.details.applicationStateWhenReceived != UIApplicationState.active {
            self.showButtons(.kButtonsAnswerDecline)
            
            if self.fromCallKit {
                self.callDidEstablish(self.call)
            } else {
                self.setCallStatusText("00:00")
                self.showButtons(.kButtonsHangup)
            }
            
        } else {
            self.setCallStatusText("CALLING...")
            self.showButtons(.kButtonsAnswerDecline)
            self.audioController?.startPlayingSoundFile(self.pathForSound("incoming.wav"), loop: true)
        }
        
        if (self.call?.details.isVideoOffered)! {
            // Add Local Video
            if self.fromCallKit || self.call?.details.applicationStateWhenReceived != UIApplicationState.active {
                self.videoController?.localView().frame = UIScreen.main.bounds
            }
            
            self.videoController?.localView().contentMode = .scaleAspectFill
            self.viewLocalVideo.addSubview((self.videoController?.localView())!)
            self.viewLocalVideo.alpha = 0
            
            UIView.animate(withDuration: 0.3, animations: {
                self.viewLocalVideo.alpha = 1
            })
        }
        
    }
    
    // MARK: Private Methods
    
    func pathForSound(_ soundName: String) -> String {
        print(Bundle.main.resourceURL!.appendingPathComponent(soundName).path)
        return Bundle.main.resourceURL!.appendingPathComponent(soundName).path
    }
    
    @objc func onDurationTimer(_ unused: Timer) {
        let duration: Int = Int(Date().timeIntervalSince((self.call?.details.establishedTime)!))
        DispatchQueue.main.async {
            self.setDuration(duration)
        }
    }
    
    // MARK: - SINCallDelegate
    
    func callDidProgress(_ call: SINCall!) {
        self.setCallStatusText("CALLING...")
        self.audioController?.startPlayingSoundFile(self.pathForSound("ringback.wav"), loop: true)
    }
    
    func callDidEstablish(_ call: SINCall!) {
        self.audioController?.disableSpeaker()
        
        if self.call?.details.isVideoOffered == false {
            if self.call?.state != SINCallState.initiating  {
                self.startCallDurationTimerWithSelector(#selector(onDurationTimer(_:)))
            } else {
                self.setCallStatusText("00:00")
            }
        } else if self.call?.details.isVideoOffered == true {
            // Disable idle timer
            UIApplication.shared.isIdleTimerDisabled = true
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self.audioController?.enableSpeaker()
            }
            
            if self.fromCallKit == true && self.call?.state != SINCallState.initiating {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    self.callDidAddVideoTrack(call)
                }
            }
            
            self.fromCallKit = false
        }
        
        self.showButtons(.kButtonsHangup)
        self.audioController?.stopPlayingSoundFile()
    }
    
    func callDidEnd(_ call: SINCall!) {
        self.audioController?.stopPlayingSoundFile()
        self.audioController?.disableSpeaker()
        self.stopCallDurationTimer()
        
        if (self.call?.details.isVideoOffered)! {
            self.videoController?.localView().removeFromSuperview()
            self.videoController?.remoteView().removeFromSuperview()
        }
        
        // Disable idle timer
        UIApplication.shared.isIdleTimerDisabled = false
        
        weak var pvc = self.presentingViewController
        self.dismiss(animated: false, completion: {
            if (call.details.endCause.rawValue == 5) { // SINCallEndCauseHungUp
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "EndCallPopupViewController") as? EndCallPopupViewController {
                    pvc?.present(vc, animated: false, completion: nil)
                }
            }
        })
    }
    
    func callDidAddVideoTrack(_ call: SINCall!) {
        self.videoController?.remoteView().frame = UIScreen.main.bounds
        self.videoController?.remoteView().contentMode = .scaleAspectFill
        self.viewRemoteVideo.addSubview((self.videoController?.remoteView())!)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            // Remove call state text
            self.lblCallState.isHidden = true
            
            // Animate Local Video
            self.constOfLocalContainerLeading.constant = 28
            self.constOfLocalContainerTop.constant = 35
            self.constOfLocalContainerTrailing.constant = Constants.ScreenWidth - 28 - 78
            self.constOfLocalContainerBottom.constant = Constants.ScreenHeight - 35 - 100
            
            self.constOfLocalVideoLeading.constant = 1
            self.constOfLocalVideoTop.constant = 1
            self.constOfLocalVideoTrailing.constant = 1
            self.constOfLocalVideoBottom.constant = 1
            
            UIView.animate(withDuration: 0.3, animations: {
                self.videoController?.localView().frame = CGRect.init(x: 0, y: 0, width: 78, height: 100)
                self.view.layoutIfNeeded()
            }) { (completed) in
                self.viewLocalContainer.backgroundColor = UIColor.white
                self.viewLocalContainer.layer.cornerRadius = 6
                self.viewLocalVideo.layer.cornerRadius = 4
                self.viewLocalVideo.layer.borderWidth = 0.5
                self.viewLocalVideo.layer.borderColor = UIColor.init(red: 147/255.0, green: 203/255.0, blue: 202/255.0, alpha: 1.0).cgColor
            }
        }
    }

}

extension CallScreenViewController {
    
    // MARK: - UI Methods
    
    fileprivate func setCallStatusText(_ text: String) {
        self.lblCallState.text = text
    }
    
    fileprivate func showButtons(_ buttons: EButtonsBar) {
        if buttons == .kButtonsAnswerDecline {
            self.viewLocalContainer.isHidden = !(self.call?.details.isVideoOffered)!
            self.viewRemoteVideo.isHidden = true
            
            self.btnSwitchCamera.isHidden = true
            self.btnSpeaker.isHidden = true
            self.btnMute.isHidden = true
            self.btnEnd.isHidden = true
        } else if buttons == .kButtonsHangup {
            if (self.call?.details.isVideoOffered)! {
                // Video Call
                self.viewRemoteVideo.isHidden = false
                self.btnSwitchCamera.isHidden = false
                
                self.viewRemoteVideo.backgroundColor = UIColor.black
                
                self.mBackgroundImageView.isHidden = true
                self.blurView.isHidden = true
                self.maskView.isHidden = true
                
                self.lblRemoteUserName.isHidden = true
                self.lblRemoteUserLocation.isHidden = true
//                self.lblCallState.isHidden = true
                
                self.setCallStatusText("CONNECTING...")
                
                // Enable landscape mode
                AppDelegate.AppUtility.lockOrientation(.all)
            }
            
            self.speakerEnabled = (self.call?.details.isVideoOffered)!
            if self.speakerEnabled {
                self.btnSpeaker.setImage(UIImage(named: "icon_call_speaker_on"), for: .normal)
            } else {
                self.btnSpeaker.setImage(UIImage(named: "icon_call_speaker"), for: .normal)
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
        self.btnAccept.isUserInteractionEnabled = false
        
        self.audioController?.stopPlayingSoundFile()
        self.call?.answer()
    }
    
    @IBAction func onSpeaker(sender: AnyObject) {
        self.speakerEnabled = !self.speakerEnabled
        
        if self.speakerEnabled {
            self.btnSpeaker.setImage(UIImage(named: "icon_call_speaker_on"), for: .normal)
            self.audioController?.enableSpeaker()
        } else {
            self.btnSpeaker.setImage(UIImage(named: "icon_call_speaker"), for: .normal)
            self.audioController?.disableSpeaker()
        }
    }
    
    @IBAction func onMute(sender: AnyObject) {
        self.muted = !self.muted
        
        if self.muted {
            self.btnMute.setImage(UIImage(named: "icon_muted"), for: .normal)
            self.audioController?.mute()
        } else {
            self.btnMute.setImage(UIImage(named: "icon_mute"), for: .normal)
            self.audioController?.unmute()
        }
    }
    
    @IBAction func onEndCall(sender: AnyObject) {
        if self.call?.state == SINCallState.ended {
            self.callDidEnd(self.call!)
        } else {
            self.call?.hangup()
        }
    }
    
}
