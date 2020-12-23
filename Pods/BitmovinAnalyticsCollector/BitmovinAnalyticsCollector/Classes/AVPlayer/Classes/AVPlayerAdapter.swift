import AVFoundation
import Foundation

class AVPlayerAdapter: CorePlayerAdapter, PlayerAdapter {
    static let timeJumpedDuplicateTolerance = 1_000
    static let maxSeekOperation = 10_000
    private static var playerKVOContext = 0
    private let config: BitmovinAnalyticsConfig
    private var drmPerformanceInfo: DrmPerformanceInfo?
    private var lastBitrate: Double = 0
    @objc private var player: AVPlayer
    let lockQueue = DispatchQueue.init(label: "com.bitmovin.analytics.avplayeradapter")
    var statusObserver: NSKeyValueObservation?
    private var isPlayingEmitted: Bool = false
    private var sendTimeUpdates = false
    private var lastTime: CMTime?
    private var timeObserver: Any?
    
    init(player: AVPlayer, config: BitmovinAnalyticsConfig, stateMachine: StateMachine) {
        self.player = player
        self.config = config
        lastBitrate = 0
        self.drmPerformanceInfo = nil
        super.init(stateMachine: stateMachine)
        self.delegate = self
        startMonitoring()
    }

    private func resetState() {
        isPlayingEmitted = false
        lastBitrate = 0
    }
    
    public func startMonitoring() {
        if(timeObserver != nil) {
            player.removeTimeObserver(timeObserver!)
        }
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.2, preferredTimescale: Int32(NSEC_PER_SEC)), queue: .main) { [weak self] time in
            self?.onPlayerDidChangeTime(currentTime: time)
        }
        
        addObserver(self, forKeyPath: #keyPath(player.rate), options: [.new, .initial, .old], context: &AVPlayerAdapter.playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(player.currentItem), options: [.new, .initial, .old], context: &AVPlayerAdapter.playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(player.status), options: [.new, .initial, .old], context: &AVPlayerAdapter.playerKVOContext)
    }

    public func stopMonitoring() {
        if let playerItem = player.currentItem {
            stopMonitoringPlayerItem(playerItem: playerItem)
        }
        removeObserver(self, forKeyPath: #keyPath(player.rate), context: &AVPlayerAdapter.playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(player.currentItem), context: &AVPlayerAdapter.playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(player.status), context: &AVPlayerAdapter.playerKVOContext)
        
        if(timeObserver != nil) {
            player.removeTimeObserver(timeObserver!)
        }
        
        resetState()
    }

    private func updateDrmPerformanceInfo(_ playerItem: AVPlayerItem) {
        if playerItem.asset.hasProtectedContent {
            self.drmPerformanceInfo = DrmPerformanceInfo(drmType: DrmType.fairplay)
        } else {
            self.drmPerformanceInfo = nil
        }
    }

    private func startMonitoringPlayerItem(playerItem: AVPlayerItem) {
        statusObserver = playerItem.observe(\.status) {[weak self] (item, _) in
            self?.playerItemStatusObserver(playerItem: item)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(accessItemAdded(notification:)), name: NSNotification.Name.AVPlayerItemNewAccessLogEntry, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(timeJumped(notification:)), name: NSNotification.Name.AVPlayerItemTimeJumped, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalled(notification:)), name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(failedToPlayToEndTime(notification:)), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: playerItem)
        updateDrmPerformanceInfo(playerItem)
    }

    private func stopMonitoringPlayerItem(playerItem: AVPlayerItem) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemNewAccessLogEntry, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemTimeJumped, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: playerItem)
        statusObserver?.invalidate()
    }

    private func playerItemStatusObserver(playerItem: AVPlayerItem) {
        let timestamp = Date().timeIntervalSince1970Millis
        switch playerItem.status {
            case .readyToPlay:
                self.isPlayerReady = true
                lockQueue.sync {
                    if stateMachine.didStartPlayingVideo && stateMachine.potentialSeekStart > 0 && (timestamp - stateMachine.potentialSeekStart) <= AVPlayerAdapter.maxSeekOperation {
                        stateMachine.confirmSeek()
                        stateMachine.transitionState(destinationState: .seeking, time: player.currentTime())
                    }
                }
            
            case .failed:
                errorOccured(error: playerItem.error as NSError?)

            default:
                break
        }
    }

    private func errorOccured(error: NSError?) {
        let errorCode = error?.code ?? 1
        let errorMessage = error?.localizedDescription ?? "Unkown"
        let errorData = error?.localizedFailureReason

        if (!stateMachine.didStartPlayingVideo && stateMachine.didAttemptPlayingVideo) {
            stateMachine.setVideoStartFailed(withReason: VideoStartFailedReason.playerError)
        }

        stateMachine.transitionState(destinationState: .error,
                                     time: player.currentTime(),
                                     data: [BitmovinAnalyticsInternal.ErrorCodeKey: errorCode,
                                            BitmovinAnalyticsInternal.ErrorMessageKey: errorMessage,
                                            BitmovinAnalyticsInternal.ErrorDataKey: errorData])
    }

    @objc private func failedToPlayToEndTime(notification: Notification) {
        let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError
        errorOccured(error: error)
    }

    @objc private func playbackStalled(notification _: Notification) {
        stateMachine.transitionState(destinationState: .buffering, time: player.currentTime())
    }

    @objc private func timeJumped(notification _: Notification) {
        let timestamp = Date().timeIntervalSince1970Millis
        if (timestamp - stateMachine.potentialSeekStart) > AVPlayerAdapter.timeJumpedDuplicateTolerance {
            stateMachine.potentialSeekStart = timestamp
            stateMachine.potentialSeekVideoTimeStart = player.currentTime()
        }
    }

    @objc private func accessItemAdded(notification: Notification) {
        guard let item = notification.object as? AVPlayerItem, let event = item.accessLog()?.events.last else {
            return
        }
        if lastBitrate == 0 {
            lastBitrate = event.indicatedBitrate
        } else if lastBitrate != event.indicatedBitrate {
            let previousState = stateMachine.state
            stateMachine.videoQualityChange(time: player.currentTime())
            stateMachine.transitionState(destinationState: previousState, time: player.currentTime())
            lastBitrate = event.indicatedBitrate
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &AVPlayerAdapter.playerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if keyPath == #keyPath(player.rate) {
            onRateChanged(change)
        } else if keyPath == #keyPath(player.currentItem) {
            if let oldItem = change?[NSKeyValueChangeKey.oldKey] as? AVPlayerItem {
                NSLog("Current Item Changed: %@", oldItem.debugDescription)
                stopMonitoringPlayerItem(playerItem: oldItem)
            }
            if let currentItem = change?[NSKeyValueChangeKey.newKey] as? AVPlayerItem {
                NSLog("Current Item Changed: %@", currentItem.debugDescription)
                startMonitoringPlayerItem(playerItem: currentItem)
            }
        } else if keyPath == #keyPath(player.status) && player.status == .failed {
            errorOccured(error: self.player.currentItem?.error as NSError?)
        }
    }
    
    private func onRateChanged(_ change: [NSKeyValueChangeKey: Any]?) {
        let oldRate = change?[NSKeyValueChangeKey.oldKey] as? NSNumber ?? 0;
        let newRate = change?[NSKeyValueChangeKey.newKey] as? NSNumber ?? 0;
        
        if(newRate.floatValue == 0 && oldRate.floatValue > 0) {
            isPlayingEmitted = false
            sendTimeUpdates = false
            stateMachine.pause(time: player.currentTime())
        } else if(newRate.floatValue > 0 && oldRate.floatValue == 0) {
            sendTimeUpdates = true
            stateMachine.play(time: player.currentTime())
        }
    }
    
    private func onPlayerDidChangeTime(currentTime: CMTime) {
        if(currentTime == lastTime || !sendTimeUpdates) {
            return
        }
        lastTime = currentTime
        onTimeChanged()
    }
    
    private func onTimeChanged() {
        emitPlayingEventIfNotYetEmitted()
    }

    private func emitPlayingEventIfNotYetEmitted() {
        if (!(player.currentItem?.isPlaybackLikelyToKeepUp ?? false) || isPlayingEmitted) {
            return;
        }
        
        stateMachine.playing(time: player.currentTime())
        isPlayingEmitted = true;
    }

    public func createEventData() -> EventData {
        let eventData: EventData = EventData(config: config, impressionId: stateMachine.impressionId)
        decorateEventData(eventData: eventData)
        return eventData
    }

    private func decorateEventData(eventData: EventData) {
        // Player
        eventData.player = PlayerType.avplayer.rawValue

        // Player Tech
        eventData.playerTech = "ios:avplayer"

        // Duration
        if let duration = player.currentItem?.duration, CMTIME_IS_NUMERIC(_: duration) {
            eventData.videoDuration = Int64(CMTimeGetSeconds(duration) * BitmovinAnalyticsInternal.msInSec)
        }

        // isCasting
        eventData.isCasting = player.isExternalPlaybackActive

        // DRM Type
        if let drmType = self.drmPerformanceInfo?.drmType {
            eventData.drmType = drmType
        }

        // isLive
        let duration = player.currentItem?.duration
        if duration != nil && self.isPlayerReady {
            eventData.isLive = CMTIME_IS_INDEFINITE(duration!)
        } else {
            eventData.isLive = config.isLive
        }

        // version
        eventData.version = PlayerType.avplayer.rawValue + "-" + UIDevice.current.systemVersion

        if let urlAsset = (player.currentItem?.asset as? AVURLAsset),
           let streamFormat = Util.streamType(from: urlAsset.url.absoluteString) {
            eventData.streamFormat = streamFormat.rawValue
            switch streamFormat {
            case .dash:
                eventData.mpdUrl = urlAsset.url.absoluteString
            case .hls:
                eventData.m3u8Url = urlAsset.url.absoluteString
            case .progressive:
                eventData.progUrl = urlAsset.url.absoluteString
            case .unknown:
                break
            }
        }

        // audio bitrate
        if let asset = player.currentItem?.asset {
            if !asset.tracks.isEmpty {
                let tracks = asset.tracks(withMediaType: .audio)
                if !tracks.isEmpty {
                    let desc = tracks[0].formatDescriptions[0] as! CMAudioFormatDescription
                    let basic = CMAudioFormatDescriptionGetStreamBasicDescription(desc)
                    if let sampleRate = basic?.pointee.mSampleRate {
                        eventData.audioBitrate = sampleRate
                    }
                }
            }
        }

        // video bitrate
        eventData.videoBitrate = lastBitrate

        // videoPlaybackWidth
        if let width = player.currentItem?.presentationSize.width {
            eventData.videoPlaybackWidth = Int(width)
        }

        // videoPlaybackHeight
        if let height = player.currentItem?.presentationSize.height {
            eventData.videoPlaybackHeight = Int(height)
        }

        let scale = UIScreen.main.scale
        // screenHeight
        eventData.screenHeight = Int(UIScreen.main.bounds.size.height * scale)

        // screenWidth
        eventData.screenWidth = Int(UIScreen.main.bounds.size.width * scale)

        // isMuted
        if player.volume == 0 {
            eventData.isMuted = true
        }
        
        // play attempt
        if (stateMachine.videoStartFailed) {
            eventData.videoStartFailed = stateMachine.videoStartFailed
            eventData.videoStartFailedReason = stateMachine.videoStartFailedReason ?? VideoStartFailedReason.unknown
            stateMachine.resetVideoStartFailed()
        }
    }

    func getDrmPerformanceInfo() -> DrmPerformanceInfo? {
        return self.drmPerformanceInfo
    }

    var currentTime: CMTime? {
        get {
            return player.currentTime()
        }
    }
}
