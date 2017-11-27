//
//  PlayerController.swift
//  MedicConnect
//
//  Created by Alessandro Zoffoli on 08/04/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import AVFoundation
import YLProgressBar

class PlayerController {
    
    static let Instance = PlayerController()
    
    var player: AVPlayer?
    var currentIndex: Int?
    var lastPlayed: PlaySlider?
    var elapsedTimeLabel: UILabel?
    var durationLabel: UILabel?
    var playerObserver: Any?
    
    var currentTime: CMTime?
    var shouldSeek: Bool = true
    
    var timerReset: Timer?
    
    func addObserver() {
        
        guard let _player = self.player as AVPlayer? else {
            return
        }
        
        self.playerObserver = _player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 10), queue: DispatchQueue.main) { (CMTime) -> Void in
            
            guard let _lastPlayed = self.lastPlayed as PlaySlider? else {
                return
            }
            
            guard let _currentIndex = self.currentIndex as Int? else {
                return
            }
            
            guard let _playerIndex = _lastPlayed.index as Int? else {
                return
            }
            
            //  Checks if we're updating the correct player.
            if _currentIndex != _playerIndex {
                _lastPlayed.setValue(0.0, animated: false)
                return
            }
            
            if _player.currentItem?.status == .readyToPlay {
                
                // Seek player only after it's ready to play
                if self.shouldSeek {
                    print("Just seek to: \(self.currentTime!)")
                    _player.seek(to: self.currentTime!)
                    self.shouldSeek = false
                }
                
                let currentTime = CGFloat(_player.currentTime().value) / CGFloat(_player.currentTime().timescale)
                
                let duration = Int(_player.currentItem!.duration.value) / Int(_player.currentItem!.duration.timescale)
                
                // Update progress
                let progress = CGFloat(currentTime) / CGFloat(duration)
                _lastPlayed.setValue(Float(progress), animated: false)
                
                // Update playing progress bar on Playlist
//                if let _playingProgressBar = self.playingProgressBar as YLProgressBar? {
//                    _playingProgressBar.progress = progress
//                }
                
                // Update state
                if !_lastPlayed.playing && _lastPlayed.value > 0 {
                    _lastPlayed.playing = true
                }
                
            } else {
                
                // Reset progress while we're not ready to play
                _lastPlayed.setValue(0.0, animated: false)
                
                // Update playing progress bar on Playlist
//                if let _playingProgressBar = self.playingProgressBar as YLProgressBar? {
//                    _playingProgressBar.progress = 0.0
//                }
            }
            
        }
        
    }
    
    func scheduleReset() {
        self.timerReset = Timer.scheduledTimer(timeInterval: 60,
                                               target: self,
                                               selector: #selector(self.resetTimer),
                                               userInfo: nil,
                                               repeats: false)
    }
    
    func invalidateTimer() {
        self.timerReset?.invalidate()
    }
    
    @objc func resetTimer() {
        self.player = nil
    }
    
}
