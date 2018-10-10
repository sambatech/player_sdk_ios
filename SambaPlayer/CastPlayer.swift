//
//  CastPlayer.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 20/09/2018.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

internal class CastPlayer: GMFVideoPlayer {
    
    fileprivate var currentPosition: CLong = 0
    fileprivate var currentDuration: CLong = 0
    
    override init() {}
    
    //MARK: - Cast Methods
    
    func start()  {
        setState(kGMFPlayerStatePlaying)
        SambaCast.sharedInstance.subscribeInternal(delegate: self)
        SambaCast.sharedInstance.registerDeviceForProgress(enable: true)
    }
    
    func destroy() {
        currentPosition = 0
        currentDuration = 0
        SambaCast.sharedInstance.unSubscribeInternal(delegate: self)
    }
    
    func syncInternalState()  {
        
        switch SambaCast.sharedInstance.playbackState {
        case .playing:
            setState(kGMFPlayerStatePlaying)
            delegate.videoPlayer(self, stateDidChangeFrom: state, to: kGMFPlayerStatePlaying)
        case .paused,.empty:
            setState(kGMFPlayerStatePaused)
            delegate.videoPlayer(self, stateDidChangeFrom: state, to: kGMFPlayerStatePaused)
        case .finished:
            setState(kGMFPlayerStateFinished)
            delegate.videoPlayer(self, stateDidChangeFrom: state, to: kGMFPlayerStateFinished)
        }
    }
    
    
    //MARK: - GMF Methods
    
    override func play() {
        SambaCast.sharedInstance.playCast()
        setState(kGMFPlayerStatePlaying)
         SambaCast.sharedInstance.playbackState = .playing
    }
    
    override func pause() {
        SambaCast.sharedInstance.pauseCast()
        setState(kGMFPlayerStatePaused)
        SambaCast.sharedInstance.playbackState = .paused
    }
    
    override func replay() {}
    
    override func seek(toTime time: TimeInterval) {
        let newPosition = CLong(time)
        SambaCast.sharedInstance.seek(to: newPosition)
        delegate.videoPlayer(self, currentMediaTimeDidChangeToTime: time)
        currentPosition = newPosition
    }
    
    override func loadStream(with asset: AVAsset!) {
        
    }
    
    override func reset() {
        currentPosition = 0
        currentDuration = 0
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
    
    func onCastFinish() {
        reset()
        delegate.videoPlayer(self, currentMediaTimeDidChangeToTime: TimeInterval(0))
        setState(kGMFPlayerStatePaused)
        delegate.videoPlayer(self, stateDidChangeFrom: state, to: kGMFPlayerStatePaused)
        SambaCast.sharedInstance.replayCast()
        SambaCast.sharedInstance.playbackState = .paused
    }
}
