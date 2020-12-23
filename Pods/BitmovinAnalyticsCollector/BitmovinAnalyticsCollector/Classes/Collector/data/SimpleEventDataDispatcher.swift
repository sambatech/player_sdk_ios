import Foundation

class SimpleEventDataDispatcher: EventDataDispatcher {
    private var httpClient: HttpClient
    private var enabled: Bool = false
    private var events = [EventData]()
    private var adEvents = [AdEventData]()
    private var config: BitmovinAnalyticsConfig
    private var sequenceNumber: Int32 = 0
    
    private var analyticsBackendUrl: String
    private var adAnalyticsBackendUrl: String

    init(config: BitmovinAnalyticsConfig) {
        httpClient = HttpClient()
        self.config = config
        self.analyticsBackendUrl = BitmovinAnalyticsConfig.analyticsUrl
        self.adAnalyticsBackendUrl = BitmovinAnalyticsConfig.adAnalyticsUrl
    }

    func makeLicenseCall() {
        let licenseCall = LicenseCall(config: config)
        licenseCall.authenticate { [weak self] success in
            if success {
                self?.enabled = true
                if let events = self?.events.enumerated().reversed() {
                    for (index, eventData) in events {
                        self?.httpClient.post(urlString: self!.analyticsBackendUrl, json: eventData.jsonString(), completionHandler: nil)
                        self?.events.remove(at: index)
                    }
                }
                if let adEvents = self?.adEvents.enumerated().reversed() {
                    for (index, adEventData) in adEvents {
                        self?.httpClient.post(urlString: self!.adAnalyticsBackendUrl, json: Util.toJson(object: adEventData), completionHandler: nil)
                        self?.adEvents.remove(at: index)
                    }
                }
            } else {
                self?.enabled = false
                NotificationCenter.default.post(name: .licenseFailed, object: self)
            }
        }
    }

    func enable() {
        makeLicenseCall()
    }

    func disable() {
        enabled = false
        self.sequenceNumber = 0
    }

    func add(eventData: EventData) {
        eventData.sequenceNumber = self.sequenceNumber
        self.sequenceNumber += 1
        if enabled {
            httpClient.post(urlString: self.analyticsBackendUrl, json: eventData.jsonString(), completionHandler: nil)
        } else {
            events.append(eventData)
        }
    }
    
    func addAd(adEventData: AdEventData) {
        if enabled {
            let json = Util.toJson(object: adEventData)
            print("send Ad payload: " + json)
            httpClient.post(urlString: self.adAnalyticsBackendUrl, json: json, completionHandler: nil)
        } else {
            adEvents.append(adEventData)
        }
    }

    func clear() {
    }
}
