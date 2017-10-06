//
//  AudioHelper.swift
//  MedicConnect
//
//  Created by Alessandro Zoffoli on 03/04/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import AVFoundation

class AudioHelper {
    
    static func SetCategory(mode: AVAudioSessionPortOverride) {
        
        do {
            
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            
        } catch {
            print(error)
        }
        
    }
    
}
