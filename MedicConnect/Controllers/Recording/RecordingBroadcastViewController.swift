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
    
    @IBOutlet weak var patientInfoView: UIStackView!
    @IBOutlet weak var lblPatientName: UILabel!
    @IBOutlet weak var lblPatientDOB: UILabel!
    @IBOutlet weak var lblPatientPHN: UILabel!
    
    fileprivate var recordingSession: AVAudioSession?
    fileprivate var audioRecorder: AVAudioRecorder?
    fileprivate var updateTimer: Timer?
    
    let exceedLimit = 120.0
    var didExceedLimit: Bool = false
    var continueRecording: Bool = false
    
    var recordingExists: Bool = false
    var recordingStartSeconds: TimeInterval = 0.0
    var shouldInsert: Bool = false
    
    fileprivate var urlRecording: URL { // recording
        get {
            return getDocumentsDirectory().appendingPathComponent("recording.m4a")
        }
    }
    
    fileprivate var urlRecordingInsert: URL { /// recording to be inserted
        get {
            return getDocumentsDirectory().appendingPathComponent("recordingInsert.m4a")
        }
    }
    
    fileprivate var urlRecordingTemp: URL { // temp recording file
        get {
            return getDocumentsDirectory().appendingPathComponent("recordingTemp.m4a")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configurePatientInfo()
        self.clearDocumentFiles()
        self.initRecording()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide Tabbar
        self.tabBarController?.tabBar.isHidden = true
        
        if didExceedLimit {
            if continueRecording {
                self.pauseRecording(isPaused: false)
            } else {
                self.stopRecording()
                self.didExceedLimit = false
                self.continueRecording = false
                self.shouldInsert = false
                
                self.performSegue(withIdentifier: Constants.SegueMedicConnectEditBroadcast, sender: nil)
            }
        } else if shouldInsert {
            self.initRecording()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Show Tabbar
        self.tabBarController?.tabBar.isHidden = false
        
        self.pauseRecording(isPaused: true)
        
    }
    
    func configurePatientInfo() {
        // Configure Patient Info
        if let _patient = DataManager.Instance.getPatient() {
            self.lblPatientName.text = _patient.name
            self.lblPatientDOB.text = _patient.getFormattedBirthDate().replacingOccurrences(of: ",", with: "")
            self.lblPatientPHN.text = _patient.patientNumber
        } else if DataManager.Instance.getPatientId() != "" {
            // Get patient with id
            PatientService.Instance.getPatientById(patientId: DataManager.Instance.getPatientId(), completion: { (success, patient) in
                if success == true && patient != nil {
                    DataManager.Instance.setPatient(patient: patient)
                    
                    DispatchQueue.main.async {
                        self.lblPatientName.text = patient?.name
                        self.lblPatientDOB.text = patient?.getFormattedBirthDate().replacingOccurrences(of: ",", with: "")
                        self.lblPatientPHN.text = patient?.patientNumber
                    }
                }
            })
        } else {
            self.patientInfoView.isHidden = true
        }
    }
    
    func clearDocumentFiles() {
        // Clear the documents folder
        do {
            let pathDocuments:String = getDocumentsDirectory().path
            
            let paths = try FileManager.default.contentsOfDirectory(atPath: pathDocuments)
            for path in paths {
                try FileManager.default.removeItem(atPath: (pathDocuments as NSString).appendingPathComponent(path))
            }
        }
        catch {
            print("error clearing temp folder: \(error)")
        }
    }
    
    func initRecording() {
        
        self.waveformView.isHidden = true
        self.waveformView.update(withLevel: 0)
        
        self.recordingSession = AVAudioSession.sharedInstance()
        
        do {
//            try recordingSession?.setCategory(AVAudioSessionCategoryPlayAndRecord)
//            try recordingSession?.setActive(true)
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
        
        let audioFilename = !self.recordingExists ? urlRecording : urlRecordingInsert // if a recording already exists, create an insert recording ('punch in' functionality)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            
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
            updateTimer?.invalidate()
        } else {
            ar.record()
            updateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(RecordingBroadcastViewController.updateSeekBar), userInfo: nil, repeats: true)
        }
    }
    
    func stopRecording() {
        
        audioRecorder?.stop()
        audioRecorder = nil
        
        updateTimer?.invalidate()
        updateTimer = nil
        
        // ******************************************************************************************
        if self.recordingExists { // if a recording already exists, insert the new recording ('punch in')
            if AudioProcessing.insert(urlRecording: self.urlRecording, urlRecordingInsert: self.urlRecordingInsert, urlResult: self.urlRecordingTemp, insertPoint: self.recordingStartSeconds) {
                
                // Success, result is in 'self.urlRecordingTemp'
                do {
                    let fileManager = FileManager.default
                    try fileManager.removeItem(at: self.urlRecording) // delete the old 'recording.m4a'
                    try fileManager.removeItem(at: self.urlRecordingInsert) // delete the old 'recordingInsert.m4a'
                    try fileManager.moveItem(at: self.urlRecordingTemp, to: self.urlRecording) // move result file to 'recording.m4a'
                } catch {
                    print("error replacing recording") // error handling here
                }
            } else {
                // Failure, 'self.urlRecordingTemp' was not created
                assert(false) // error handling here
            }
        }
        
        // ******************************************************************************************
        
        self.recordingStartSeconds = 0.0
        self.recordingExists = true
        
    }
    
    @objc func updateSeekBar() {
        
        if let _audioRecorder = self.audioRecorder as AVAudioRecorder? {
            if !didExceedLimit && _audioRecorder.currentTime >= exceedLimit {
                self.pauseRecording(isPaused: true)
                self.didExceedLimit = true
                self.continueRecording = false
                self.shouldInsert = false
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                if let vc = storyboard.instantiateViewController(withIdentifier: "ErrorPopupViewController") as? ErrorPopupViewController {
                    vc.popupType = .exceedLimit
                    self.navigationController?.pushViewController(vc, animated: false)
                }
                
            } else {
                _audioRecorder.updateMeters()
                let normalizedValue:CGFloat = pow(10, CGFloat(_audioRecorder.averagePower(forChannel: 0)) / 40)
                self.waveformView.update(withLevel: normalizedValue)
                
                let progress = _audioRecorder.currentTime
                self.lblCurrentTime.text = progress.durationText + " sec"
            }
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
        self.stopRecording()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.shouldReceiveCall = true
        
        if let _nav = self.navigationController as UINavigationController? {
            _nav.dismiss(animated: false, completion: nil)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func onStopRecording(sender: AnyObject) {
        self.pauseRecording(isPaused: true)
        
        AlertUtil.showConfirmAlert(self, title: NSLocalizedString("Are you sure you want to stop\nrecording?", comment: "comment"), message: nil, okButtonTitle: NSLocalizedString("STOP RECORDING", comment: "comment"), cancelButtonTitle: NSLocalizedString("KEEP RECORDING", comment: "comment"), okCompletionBlock: {
            // OK completion block
            self.stopRecording()
            self.didExceedLimit = false
            self.continueRecording = false
            self.shouldInsert = false
            
            self.performSegue(withIdentifier: Constants.SegueMedicConnectEditBroadcast, sender: nil)
        }, cancelCompletionBlock: {
            // Cancel completion block
            self.pauseRecording(isPaused: false)
        })
    }
    
}
