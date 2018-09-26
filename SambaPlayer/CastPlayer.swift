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
        currentPosition = position / 1000
        currentDuration = duration / 1000
        delegate.videoPlayer(self, currentTotalTimeDidChangeToTime: TimeInterval(currentDuration))
        delegate.videoPlayer(self, currentMediaTimeDidChangeToTime: TimeInterval(currentPosition))
    }
}
