import AVFoundation
import Foundation
/**
 * An iOS analytics plugin that sends video playback analytics to Bitmovin Analytics servers. Currently
 * supports analytics on AVPlayer video players
 */
public class BitmovinAnalyticsInternal: NSObject {
    public static let ErrorMessageKey = "errorMessage"
    public static let ErrorCodeKey = "errorCode"
    public static let ErrorDataKey = "errorData"

    static let msInSec = 1_000.0
    internal var config: BitmovinAnalyticsConfig
    internal var stateMachine: StateMachine
    internal var adapter: PlayerAdapter?
    private var eventDataDispatcher: EventDataDispatcher
    internal var adAnalytics: BitmovinAdAnalytics?
    internal var adAdapter: AdAdapter?
    internal var didSendDrmLoadTime = false

    internal init(config: BitmovinAnalyticsConfig) {
        self.config = config
        stateMachine = StateMachine(config: self.config)
        eventDataDispatcher = SimpleEventDataDispatcher(config: config)
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(licenseFailed(notification:)), name: .licenseFailed, object: eventDataDispatcher)
        NotificationCenter.default.addObserver(self,
            selector: #selector(applicationWillTerminate(notification:)),
            name: UIApplication.willTerminateNotification,
            object: nil)
        
        if (config.ads) {
            self.adAnalytics = BitmovinAdAnalytics(analytics: self);
        }
    }
    
    deinit {
        self.detachPlayer()
    }
    
    /**
     * Detach the current player that is being used with Bitmovin Analytics.
     */
    @objc public func detachPlayer() {
        detachAd();
        adapter?.destroy()
        eventDataDispatcher.disable()
        stateMachine.reset()
        adapter = nil
    }

    internal func attach(adapter: PlayerAdapter, autoplay: Bool) {
        stateMachine.delegate = self
        eventDataDispatcher.enable()
        self.adapter = adapter
        if(autoplay) {
            stateMachine.transitionState(destinationState: .startup, time: nil)
        }
    }
    
    private func detachAd() {
        adAdapter?.releaseAdapter()
    }
    
    internal func attachAd(adAdapter: AdAdapter) {
        self.adAdapter = adAdapter;
    }
    
    @objc private func licenseFailed(notification _: Notification) {
        detachPlayer()
    }
    
    @objc private func applicationWillTerminate(notification _: Notification) {
        detachPlayer()
    }

    private func sendEventData(eventData: EventData?) {
        guard let data = eventData else {
            return
        }
        eventDataDispatcher.add(eventData: data)
    }
    
    internal func sendAdEventData(adEventData: AdEventData?) {
        guard let data = adEventData else {
            return
        }
        eventDataDispatcher.addAd(adEventData: data)
    }

    private func createEventData(duration: Int64) -> EventData? {
        guard let eventData = adapter?.createEventData() else {
            return nil
        }
        eventData.state = stateMachine.state.rawValue
        eventData.duration = duration

        if !self.didSendDrmLoadTime,  let drmLoadTime = self.adapter?.getDrmPerformanceInfo()?.drmLoadTime {
            self.didSendDrmLoadTime = true
            eventData.drmLoadTime = drmLoadTime
        }

        if let timeStart = stateMachine.videoTimeStart, CMTIME_IS_NUMERIC(_: timeStart) {
            eventData.videoTimeStart = Int64(CMTimeGetSeconds(timeStart) * BitmovinAnalyticsInternal.msInSec)
        }
        if let timeEnd = stateMachine.videoTimeEnd, CMTIME_IS_NUMERIC(_: timeEnd) {
            eventData.videoTimeEnd = Int64(CMTimeGetSeconds(timeEnd) * BitmovinAnalyticsInternal.msInSec)
        }
        return eventData
    }
}

extension BitmovinAnalyticsInternal: StateMachineDelegate {

    func stateMachineDidExitSetup(_ stateMachine: StateMachine) {
    }

    func stateMachineEnterPlayAttemptFailed(stateMachine: StateMachine) {
        let eventData = createEventData(duration: 0)
        sendEventData(eventData: eventData)
    }
    
    func stateMachine(_ stateMachine: StateMachine, didExitBufferingWithDuration duration: Int64) {
        let eventData = createEventData(duration: duration)
        eventData?.buffered = duration
        sendEventData(eventData: eventData)
    }

    func stateMachineDidEnterError(_ stateMachine: StateMachine, data: [AnyHashable: Any]?) {
        let eventData = createEventData(duration: 0)
        if let errorCode = data?[BitmovinAnalyticsInternal.ErrorCodeKey] {
            eventData?.errorCode = errorCode as? Int
        }
        if let errorMessage = data?[BitmovinAnalyticsInternal.ErrorMessageKey] {
            eventData?.errorMessage = errorMessage as? String
        }
        if let errorData = data?[BitmovinAnalyticsInternal.ErrorDataKey] {
            eventData?.errorData = errorData as? String
        }
        sendEventData(eventData: eventData)
    }

    func stateMachine(_ stateMachine: StateMachine, didExitPlayingWithDuration duration: Int64) {
        let eventData = createEventData(duration: duration)
        eventData?.played = duration
        sendEventData(eventData: eventData)
    }

    func stateMachine(_ stateMachine: StateMachine, didExitPauseWithDuration duration: Int64) {
        let eventData = createEventData(duration: duration)
        eventData?.paused = duration
        sendEventData(eventData: eventData)
    }

    func stateMachineDidQualityChange(_ stateMachine: StateMachine) {
        let eventData = createEventData(duration: 0)
        sendEventData(eventData: eventData)
    }

    func stateMachine(_ stateMachine: StateMachine, didExitSeekingWithDuration duration: Int64, destinationPlayerState: PlayerState) {
        let eventData = createEventData(duration: duration)
        eventData?.seeked = duration
        sendEventData(eventData: eventData)
    }

    func stateMachine(_ stateMachine: StateMachine, didHeartbeatWithDuration duration: Int64) {
        let eventData = createEventData(duration: duration)
        switch stateMachine.state {
        case .playing:
            eventData?.played = duration

        case .paused:
            eventData?.paused = duration

        case .buffering:
            eventData?.buffered = duration

        default:
            break
        }
        sendEventData(eventData: eventData)
    }

    func stateMachine(_ stateMachine: StateMachine, didStartupWithDuration duration: Int64) {
        let eventData = createEventData(duration: duration)
        eventData?.videoStartupTime = duration
        // Hard coding 1 as the player startup time to workaround a Dashboard issue
        eventData?.playerStartupTime = 1
        eventData?.startupTime = duration + 1
        eventData?.supportedVideoCodecs = Util.getSupportedVideoCodecs()

        eventData?.state = "startup"
        sendEventData(eventData: eventData)
    }

    func stateMachineDidSubtitleChange(_ stateMachine: StateMachine) {
        let eventData = createEventData(duration: 0)
        sendEventData(eventData: eventData)
    }

    func stateMachineDidAudioChange(_ stateMachine: StateMachine) {
        let eventData = createEventData(duration: 0)
        sendEventData(eventData: eventData)
    }

    var currentTime: CMTime? {
        get {
            return self.adapter?.currentTime
        }
    }
}
