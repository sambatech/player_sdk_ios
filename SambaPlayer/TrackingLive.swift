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
        player?.unsubscribeDelegate(self)
        if sttm2 != nil {
            sttm2?.destroy()
            sttm2 = nil
        }
    }
    
}



class STTM2 {
    
    private static let ORIGIN_SDK_IOS = "player.sambatech.sdk.ios"
    
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
	
	func destroy() {
		#if DEBUG
		print("destroy")
		#endif
		
		cancelOnEventTask()
	}

	
	@objc private func timerHandlerOnEvent() {
		trackOnEvent()
	}
    
    
    private func sendEvents(_ events: STTM2Event...) {
        
        var finalEvent: String!
        
        if events.count > 1 {
            finalEvent = events.map{$0.rawValue}.joined(separator: ",")
        } else {
            finalEvent = events[0].rawValue
        }
        
        sendRequest(with: finalEvent)
        
    }
    
    private func sendRequest(with event: String) {
        
        getSTTM2Data { [weak self] sttm2Data in
            guard let strongSelf = self else {return}
            guard let mSTTM = sttm2Data else {return}
            
            let urlString = "\(mSTTM.url)?event=\(event)&cid=\(strongSelf._media.clientId)&pid=\(strongSelf._media.projectId)&lid=\(strongSelf._media.id)&cat=\(strongSelf._media.categoryId)&org=\(STTM2.ORIGIN_SDK_IOS)"
            
            var urlRequest = URLRequest(url: URL(string: urlString)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Helpers.requestTimeout)
            
            urlRequest.setValue("Bearer \(mSTTM.key)", forHTTPHeaderField: "Authorization")
            urlRequest.setValue(Helpers.getUserAgentString(), forHTTPHeaderField: "User-Agent")
            urlRequest.httpMethod = "GET"
            
            
            Helpers.requestURLWithHttpResponse(urlRequest, {(data: Data?, response: HTTPURLResponse?) in
                print(response?.statusCode)
            })
        }
       
    }
    
    
    private func getSTTM2Data(_ onComplete: @escaping (_ sttm2data: STTM2Data?) -> Void) {
        let urlString = "\(Helpers.settings["playerapi_endpoint_prod"]!)\(_media.projectHash)/jwt/\(_media.id)"
        
        
        let urlRequest = URLRequest(url: URL(string: urlString)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Helpers.requestTimeout)
        
        Helpers.requestURLWithHttpResponse(urlRequest, { [weak self] (data: Data?, response: HTTPURLResponse?) in
            
            guard let strongSelf = self else {return}
            
            if (response?.statusCode)! >= 200 && (response?.statusCode)! <= 299 {
                let responseText = String(data: data!, encoding: .utf8)!
                
                var tokenBase64: String = responseText
                
                let mediaId = strongSelf._media.id
                
                if let m = mediaId.range(of: "\\d(?=[a-zA-Z]*$)", options: .regularExpression),
                    let delimiter = Int(mediaId[m]) {
                    tokenBase64 = responseText.substring(with: responseText.characters.index(responseText.startIndex, offsetBy: delimiter)..<responseText.characters.index(responseText.endIndex, offsetBy: -delimiter))
                }
                
                tokenBase64 = tokenBase64.replacingOccurrences(of: "-", with: "+")
                    .replacingOccurrences(of: "_", with: "/")
                
                switch tokenBase64.characters.count % 4 {
                case 2:
                    tokenBase64 += "=="
                case 3:
                    tokenBase64 += "="
                default: break
                }
                
                guard let jsonText = Data(base64Encoded: tokenBase64, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) else {
                    print("\(type(of: self)) Error: Base64 token failed to create encoded data.")
                    return
                }
                
                let sttm2Data = try? STTM2Data(anyObject: JSONSerialization.jsonObject(with: jsonText, options: .allowFragments) as AnyObject)
                
                onComplete(sttm2Data)
                
            }
        }) { (player, response) in
            onComplete(nil)
        }
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


fileprivate struct STTM2Data {
    
    var key: String
    var url: String
    
    init(anyObject: AnyObject) {
        key = anyObject["key"] as! String
        url = anyObject["url"] as! String
    }
    
}
