//
//  AudioHelper.swift
//  MedicConnect
//
//  Created by Alessandro Zoffoli on 03/04/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import AVFoundation

class AudioHelper {
    
    static var overrideMode: AVAudioSessionPortOverride = .speaker
    
    static func SetCategory(mode: AVAudioSessionPortOverride) {
        
        do {
            
            if mode == .speaker {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions(rawValue: AVAudioSessionCategoryOptions.RawValue(UInt8(AVAudioSessionCategoryOptions.defaultToSpeaker.rawValue) | UInt8(AVAudioSessionCategoryOptions.allowBluetooth.rawValue))))
                try AVAudioSession.sharedInstance().setActive(true)
                
            } else {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.allowBluetooth)
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(mode)
                try AVAudioSession.sharedInstance().setActive(true)
            }
            
            self.overrideMode = mode
            
        } catch {
            print(error)
        }
        
    }
    
}
