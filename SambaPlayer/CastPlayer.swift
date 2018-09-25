//
//  CastPlayer.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 20/09/2018.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

class CastPlayer: GMFVideoPlayer {
    
    override init() {}
    
    //MARK: - Cast Methods
    
    func start()  {
        SambaCast.sharedInstance.subscribe(delegate: self)
    }
    
    func destroy() {
        SambaCast.sharedInstance.unSubscribe(delegate: self)
    }
    
    
    //MARK: - GMF Methods
    
    override func play() {
         setState(kGMFPlayerStatePlaying)
    }
    
    override func pause() {
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
        setState(kGMFPlayerStatePaused)
        return TimeInterval(400)
    }
    
    override func totalMediaTime() -> TimeInterval {
        return TimeInterval(2000)
    }
    
    override func bufferedMediaTime() -> TimeInterval {
        return TimeInterval(600)
    }
    
    override func getCurrentSeekableTimeRange() -> CMTimeRange {
        return CMTimeRange()
    }
    
    
}

extension CastPlayer: SambaCastDelegate {
    
    func onCastProgress(position: CLong, duration: CLong) {
        
    }
}
