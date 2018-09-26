//
//  CastPlayer.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 20/09/2018.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

class CastPlayer: GMFVideoPlayer {
    
    fileprivate var currentPosition: CLong = 0
    fileprivate var currentDuration: CLong = 0
    
    override init() {}
    
    //MARK: - Cast Methods
    
    func start()  {
        SambaCast.sharedInstance.subscribe(delegate: self)
        SambaCast.sharedInstance.registerDeviceForProgress(enable: true)
    }
    
    func destroy() {
        currentPosition = 0
        currentDuration = 0
        SambaCast.sharedInstance.unSubscribe(delegate: self)
    }
    
    
    //MARK: - GMF Methods
    
    override func play() {
        SambaCast.sharedInstance.playCast()
        setState(kGMFPlayerStatePlaying)
    }
    
    override func pause() {
        SambaCast.sharedInstance.pauseCast()
        setState(kGMFPlayerStatePaused)
    }
    
    override func replay() {
        
    }
    
    override func seek(toTime time: TimeInterval) {
        let newPosition = CLong(time)
        SambaCast.sharedInstance.seek(to: newPosition)
        delegate.videoPlayer(self, currentMediaTimeDidChangeToTime: time)
        currentPosition = newPosition
    }
    
    override func loadStream(with asset: AVAsset!) {
        
    }
    
    override func reset() {
        
    }
    
    override func currentMediaTime() -> TimeInterval {
        return TimeInterval(currentPosition)
    }
    
    override func totalMediaTime() -> TimeInterval {
        return TimeInterval(currentDuration)
    }
    
    override func bufferedMediaTime() -> TimeInterval {
        return TimeInterval(currentPosition)
    }
    
    override func getCurrentSeekableTimeRange() -> CMTimeRange {
        return CMTimeRange()
    }
    
    
}

extension CastPlayer: SambaCastDelegate {
    
    func onCastProgress(position: CLong, duration: CLong) {
        currentPosition = position
        currentDuration = duration
        delegate.videoPlayer(self, currentTotalTimeDidChangeToTime: TimeInterval(currentDuration))
        delegate.videoPlayer(self, currentMediaTimeDidChangeToTime: TimeInterval(currentPosition))
    }
}
