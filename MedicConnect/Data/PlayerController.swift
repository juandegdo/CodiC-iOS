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
    var lastPlayed: SVGPlayButton?
    var playingProgressBar: YLProgressBar?
    var playerObserver: Any?
    
    var currentTime: CMTime?
    var shouldSeek: Bool = true
    
    var timerReset: Timer?
    
    func addObserver() {
        
        guard let _player = self.player as AVPlayer? else {
            return
        }
        
        self.playerObserver = _player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 10), queue: DispatchQueue.main) { (CMTime) -> Void in
            
            guard let _lastPlayed = self.lastPlayed as SVGPlayButton? else {
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
                _lastPlayed.progressStrokeEnd = 0.0
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
                
                // Restore current tick count from audio
                _lastPlayed.tickCount = currentTime
                
                // Increment tick count
                _lastPlayed.tickCount += 0.1
                
                // Update progress
                let progress = CGFloat(_lastPlayed.tickCount) / CGFloat(duration)
                _lastPlayed.progressStrokeEnd = progress
                
                // Update playing progress bar on Playlist
                if let _playingProgressBar = self.playingProgressBar as YLProgressBar? {
                    _playingProgressBar.progress = progress
                }
                
                // Update state
                if !_lastPlayed.playing && _lastPlayed.progressStrokeEnd > 0 {
                    _lastPlayed.playing = true
                }
                
            } else {
                
                // Reset progress while we're not ready to play
                _lastPlayed.progressStrokeEnd = 0.0
                
                // Update playing progress bar on Playlist
                if let _playingProgressBar = self.playingProgressBar as YLProgressBar? {
                    _playingProgressBar.progress = 0.0
                }
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
