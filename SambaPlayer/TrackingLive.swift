import Foundation




//private static final String EVENT_LOAD = "lo";
//private static final String EVENT_PLAY = "pl";
//private static final String EVENT_PAUSE = "pa";
//private static final String EVENT_ONLINE = "on";
//private static final String EVENT_COMPLETE = "co";

class TrackingLive: NSObject, Tracking {

	fileprivate weak var player: SambaPlayer?
	fileprivate var sttm2: STTM2?
    
    func onLoadPlugin(with player: SambaPlayer) {
        self.player = player

        player.delegate = self
    }
    
    
    func onDestroyPlugin() {
        
    }
    
}

class STTM2 {
    
    fileprivate static let EVENT_LOAD = "lo"
    fileprivate static let EVENT_PLAY = "pl"
    fileprivate static let EVENT_PAUSE = "pa"
    fileprivate static let EVENT_ONLINE = "on"
    
	private var _media: SambaMediaConfig
	private var _timer: Timer?
	private var _targets = [String]()
	private var _progresses = NSMutableOrderedSet()
	private var _trackedRetentions = Set<Int>()
    
    private var isEventTimerTaskRunning: Bool = false
	
	init(_ media: SambaMediaConfig) {
		_media = media
		
	}
	
    func startOnEventTask()  {
        _timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(timerHandlerOnEvent), userInfo: nil, repeats: true)
        isEventTimerTaskRunning = true
    }
    
    func isOnEventTaskRunning() -> Bool {
        return isEventTimerTaskRunning
    }
    
    func cancelOnEventTask() {
        guard let mTimer = _timer else {return}
        mTimer.invalidate()
        isEventTimerTaskRunning = false
    }
    
	func trackStart() {
    
	}
    
    func trackPlayAndONEvent() {
        
    }
    
    func trackPauseEvent() {
        
    }
    
    func trackLoadEvent() {
        
    }
    
    func trackOnEvent() {
        
    }
    
    func sendEvents(_ events: String...) {
        
        var finalEvent: String?
        
        if events.count > 1 {
            finalEvent = events.joined(separator: ",")
        } else {
            finalEvent = events[0]
        }
        
        
//        String finalEvents = null;
//        if (events.length > 1) {
//            finalEvents = TextUtils.join(",", events);
//        } else {
//            finalEvents = events[0];
//        }
//
//        new RequestTrackerLiveTask().execute(finalEvents);
    }
	
	func destroy() {
		#if DEBUG
		print("destroy")
		#endif
		
		cancelOnEventTask()
	}

	
	@objc private func timerHandlerOnEvent() {
		
	}
}

//MARK: - Extensions

extension TrackingLive: SambaPlayerDelegate {
    
    func onStart() {
//        guard let media = player.media as? SambaMediaConfig,
//            !media.isLive && !media.isAudio
//            else { return }
//        sttm2 = STTM2(media)
        sttm2?.trackStart()
    }
    
    func onLoad() {
        sttm2?.trackLoadEvent()
    }
    
    func onResume() {
        sttm2?.trackPlayAndONEvent()
    }
    
    func onPause() {
        sttm2?.trackPauseEvent()
    }
    
    func onFinish() {
        sttm2?.destroy()
    }
    
    func onReset() {
        onDestroy()
    }
    
    func onDestroy() {
        sttm2?.destroy()
    }
    
}
