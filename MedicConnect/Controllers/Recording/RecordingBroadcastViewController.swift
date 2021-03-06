//
//  RecordingBroadcastViewController.swift
//  MedicConnect
//
//  Created by alessandro on 12/3/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit
import AVFoundation

class RecordingBroadcastViewController: BaseViewController {
    
    @IBOutlet var lblCurrentTime: UILabel!
    @IBOutlet var waveformView: SCSiriWaveformView!
    
    fileprivate var recordingSession: AVAudioSession?
    fileprivate var audioRecorder: AVAudioRecorder?
    fileprivate var updateTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initRecording()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
    }
    
    func initRecording() {
        
        self.waveformView.isHidden = true
        self.waveformView.update(withLevel: 0)
        
        self.recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession?.setActive(true)
            recordingSession?.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.startRecording()
                    } else {
                        print("failed to record!")
                    }
                }
            }
        } catch {
            print("failed to record!")
        }
        
    }
    
    func startRecording() {
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            
            AudioHelper.SetCategory(mode: AVAudioSessionPortOverride.none)
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            self.waveformView.isHidden = false
            
            self.updateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(RecordingBroadcastViewController.updateSeekBar), userInfo: nil, repeats: true)
            
        } catch {
            self.stopRecording()
        }
        
    }
    
    func pauseRecording(isPaused: Bool) {
        guard let ar = audioRecorder else {
            return
        }
        
        if (isPaused) {
            ar.pause()
        } else {
            ar.record()
        }
    }
    
    func stopRecording() {
        
        audioRecorder?.stop()
        audioRecorder = nil
    
    }
    
    func updateSeekBar() {
        
        if let _audioRecorder = self.audioRecorder as AVAudioRecorder? {
            _audioRecorder.updateMeters()
            let normalizedValue:CGFloat = pow(10, CGFloat(_audioRecorder.averagePower(forChannel: 0)) / 40)
            self.waveformView.update(withLevel: normalizedValue)
            
            let progress = _audioRecorder.currentTime
            self.lblCurrentTime.text = progress.durationText + " sec"
        }
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func normalizedPowerLevelFromDecibels(decibels: CGFloat) -> CGFloat {
        if (decibels < -60.0 || decibels == 0.0) {
            return 0.0
        }
        
        return CGFloat(powf((powf(10.0, Float(0.05 * decibels)) - powf(10.0, 0.05 * -60.0)) * (1.0 / (1.0 - powf(10.0, 0.05 * -60.0))), 1.0 / 2.0))
    }
    
}

extension RecordingBroadcastViewController {
    //MARK: IBActions
    
    @IBAction func onClose(sender: AnyObject) {
        stopRecording()
        
        self.tabBarController?.selectedIndex = DataManager.Instance.getLastTabIndex()
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    @IBAction func onStopRecording(sender: AnyObject) {
        self.pauseRecording(isPaused: true)
        
        AlertUtil.showConfirmAlert(self, message: NSLocalizedString("RECORDING PAUSED\nWould you like to continue recording?", comment: "comment"), okButtonTitle: NSLocalizedString("I'M DONE", comment: "comment"), cancelButtonTitle: NSLocalizedString("CONTINUE", comment: "comment"), okCompletionBlock: {
            // OK completion block
            self.stopRecording()
            self.performSegue(withIdentifier: Constants.SegueMedicConnectEditBroadcast, sender: nil)
        }, cancelCompletionBlock: {
            // Cancel completion block
            self.pauseRecording(isPaused: false)
        })
    }
    
}
