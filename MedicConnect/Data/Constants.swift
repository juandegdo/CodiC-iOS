//
//  Constants.swift
//  MedicConnect
//
//  Created by alessandro on 11/26/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit

class Constants {
    
    // MARK: Segue Constants
    static let SegueMedicConnectWelcome = "segueToWelcome"
    static let SegueMedicConnectSignup = "Signup"
    static let SegueMedicConnectWelcomeProfile = "segueToWelcomeProfile"
    static let SegueMedicConnectWelcomeFinal = "WelcomeFinal"
    static let SegueMedicConnectHome = "GoHome"
    static let SegueMedicConnectSignIn = "GoSignIn"
    static let SegueMedicConnectShareBroadcastPopup = "ShareBroadcastPopUp"
    static let SegueMedicConnectRecordingBroadcast = "RecordingBroadcast"
    static let SegueMedicConnectEditBroadcast = "EditRecordingBroadcast"
    static let SegueMedicConnectStopBroadcast = "StopRecordingBroadcast"
    static let SegueMedicConnectSaveBroadcast = "SaveBroadcast"
    static let SegueMedicConnectShareBroadcast = "ShareBroadcast"
    
    static let SampleURL1 = "http://54.68.190.196:1935/audio/audio1.m4a/playlist.m3u8"
    static let SampleURL2 = "http://54.68.190.196:1935/audio/audio2.m4a/playlist.m3u8"
    
    // MARK: Colors
    
    static let ColorOrange: UIColor = UIColor(red: 244/255, green: 145/255, blue: 28/255, alpha: 1.0)
    static let ColorRed: UIColor = UIColor(red: 243/255, green: 52/255, blue: 47/255, alpha: 1.0)

    static let ColorLightGray: UIColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 0.75)
    
    static let ColorDarkGray: UIColor = UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0)
    static let ColorDarkGray1: UIColor = UIColor(red: 29/255, green: 29/255, blue: 38/255, alpha: 1.0)
    static let ColorDarkGray2: UIColor = UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 0.5)
    static let ColorDarkGray3: UIColor = UIColor(red: 117/255, green: 117/255, blue: 133/255, alpha: 1.0)
    
    static let ColorTabSelected : UIColor = UIColor(red: 249/255, green: 36/255, blue: 60/255, alpha: 1.0)
    
    struct BrodcastPlayerStatus {
        static let None = 0
        static let Playing = 1
        static let Paused = 2
        static let Stopped = 3
    }
    
    static let ProfileTabIndex = 1
    
    
    static let ScreenHeight = UIScreen.main.bounds.size.height
    static let ScreenWidth = UIScreen.main.bounds.size.width
    
    static let MaxPhoneNumberLength = 15
    static let MaxFullNameLength = 100
    static let MaxDescriptionLength = 500
    
    
    //// Identifiers
    static let FollowerCellID = "FollowerCell"
    static let PlaylistCellID = "PlaylistCell"
}
