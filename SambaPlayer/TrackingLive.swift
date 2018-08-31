import Foundation

class TrackingLive: NSObject, Tracking {

	fileprivate weak var player: SambaPlayer?
	fileprivate var sttm2: STTM2?
    
    func onLoadPlugin(with player: SambaPlayer) {
        self.player = player

        sttm2 = STTM2(player.media as! SambaMediaConfig)
        
        player.delegate = self
    }
    
    
    func onDestroyPlugin() {
        if sttm2 != nil {
            sttm2?.destroy()
            sttm2 = nil
        }
    }
    
}



class STTM2 {
    
    enum STTM2Event: String {
        case load = "lo"
        case play = "pl"
        case pause = "pa"
        case online = "on"
    }
    
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
        _timer = nil
        isEventTimerTaskRunning = false
    }
    
    func trackPlayAndONEvent() {
        sendEvents(.play, .online)
    }
    
    func trackPauseEvent() {
        sendEvents(.pause)
    }
    
    func trackLoadEvent() {
        sendEvents(.load)
    }
    
    func trackOnEvent() {
        sendEvents(.online)
    }
    
    func sendEvents(_ events: STTM2Event...) {
        
        var finalEvent: String?
        
        if events.count > 1 {
            finalEvent = events.map{$0.rawValue}.joined(separator: ",")
        } else {
            finalEvent = events[0].rawValue
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
		trackOnEvent()
	}
}

//MARK: - Extensions

extension TrackingLive: SambaPlayerDelegate {
    
    func onLoad() {
        sttm2?.trackLoadEvent()
    }
    
    func onResume() {
        if let mSttm2 = sttm2, !mSttm2.isOnEventTaskRunning() {
            sttm2?.trackPlayAndONEvent()
            sttm2?.startOnEventTask()
        }
    }
    
    func onPause() {
        sttm2?.cancelOnEventTask()
        sttm2?.trackPauseEvent()
    }
    
    func onError(_ error: SambaPlayerError) {
        sttm2?.cancelOnEventTask()
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
