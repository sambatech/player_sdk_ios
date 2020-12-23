import Foundation

public class BitmovinAdAnalytics {
    
    private var analytics: BitmovinAnalyticsInternal
    
    private var adPodPosition = 0
    private var adStartupTimestamp: TimeInterval? = nil
    private var beginPlayingTimestamp: TimeInterval? = nil
    private var activeAdSample: AdSample? = nil
    private var activeAdBreak: AnalyticsAdBreak? = nil
    private var isPlaying = false
    private var adManifestDownloadTimes = [String: TimeInterval]()
        
    private var _currentTime: TimeInterval?
    private var currentTime: TimeInterval? {
        get {
            if (self.isPlaying) {
                if (_currentTime == nil || self.beginPlayingTimestamp == nil) {
                    return nil
                } else {
                    return _currentTime! + Date().timeIntervalSince1970 - self.beginPlayingTimestamp!
                }
            } else {
                return _currentTime
            }
        }
        set {
            self._currentTime = newValue
        }
    }
    
    internal init(analytics: BitmovinAnalyticsInternal) {
        self.analytics = analytics;
        self.adManifestDownloadTimes = [String: TimeInterval]()
    }
    
    deinit {
        self.activeAdBreak = nil;
        self.activeAdSample = nil;
        self.currentTime = nil;
    }
    
    public func onAdManifestLoaded(adBreak: AnalyticsAdBreak, downloadTime: TimeInterval) {
        self.adManifestDownloadTimes[adBreak.id] = downloadTime;
        if (adBreak.tagType == AdTagType.VMAP) {
            sendAnalyticsRequest(adBreak: adBreak);
        }
        print("OnAdManifestLoaded in \(downloadTime)")
    }
    
    public func onAdStarted(ad: AnalyticsAd) {
        print("onAdStarted")
        
        let currentTimestamp = Date().timeIntervalSince1970
        
        resetActiveAd()
        let adSample = AdSample()
        adSample.ad = ad
        
        if let adStartupTime = self.adStartupTimestamp {
            adSample.adStartupTime = currentTimestamp - adStartupTime
        }
        
        adSample.started = 1
        adSample.timePlayed = 0
        adSample.timeInViewport = 0
        adSample.adPodPosition = self.adPodPosition

        self.activeAdSample = adSample
        
        self.beginPlayingTimestamp = currentTimestamp
        self.isPlaying = true
        self.currentTime = 0
        self.adPodPosition += 1
    }
    
    public func onAdFinished(){
        print("onAdFinished")
        guard let adSample = self.activeAdSample else {
            return
        }
        guard let adBreak = self.activeAdBreak else {
            return
        }
        
        adSample.completed = 1
        completeAd(adBreak: adBreak, adSample:adSample, exitPosition: adSample.ad.duration)
    }
    
    public func onAdBreakStarted(adBreak: AnalyticsAdBreak) {
        print("onAdBreakStarted")
        self.adPodPosition = 0
        self.activeAdBreak = adBreak
        self.adStartupTimestamp = Date().timeIntervalSince1970
    }
    
    public func onAdBreakFinished() {
        print("onAdBreakFinished")
        self.activeAdBreak = nil
        resetActiveAd()
    }
    
    public func onAdClicked(clickThroughUrl: String?) {
        print("onAdClicked")
        guard let adSample = self.activeAdSample else {
            return
        }
        
        adSample.ad.clickThroughUrl = clickThroughUrl
        adSample.clicked = 1
        adSample.clickPosition = self.currentTime
        if let duration = adSample.ad.duration {
            adSample.clickPercentage = Util.calculatePercentageForTimeInterval(numerator: adSample.clickPosition, denominator: duration, clamp: true)
        }
    }
    
    public func onAdSkipped() {
        print("onAdSkipped")
        guard let adSample = self.activeAdSample else {
            return
        }
        guard let adBreak = self.activeAdBreak else {
            return
        }
        
        adSample.skipped = 1
        adSample.skipPosition = self.currentTime
        if let duration = adSample.ad.duration {
            adSample.skipPercentage = Util.calculatePercentageForTimeInterval(numerator: adSample.skipPosition, denominator: duration, clamp: true)
        }
        
        completeAd(adBreak: adBreak, adSample: adSample, exitPosition: adSample.skipPosition)
    }
        
    public func onAdError(adBreak: AnalyticsAdBreak, code: Int?, message: String?) {
        print("onAdError")
        let adSample = self.activeAdSample ?? AdSample()
        
        if (adSample.ad.id != nil && adBreak.ads.contains { $0.id == adSample.ad.id }) {
            adSample.errorPosition = self.currentTime
            if let duration = adSample.ad.duration {
                adSample.errorPercentage = Util.calculatePercentageForTimeInterval(numerator: adSample.errorPosition, denominator: duration, clamp: true)
            }
        }
        
        adSample.errorCode = code
        adSample.errorMessage = message
        
        completeAd(adBreak: adBreak, adSample: adSample, exitPosition: adSample.errorPosition ?? 0)
    }
    
    public func onAdQuartile(quartile: AnalyticsAdQuartile) {
        guard self.activeAdSample != nil else {
            return;
        }
        
        switch quartile {
            case AnalyticsAdQuartile.FIRST_QUARTILE:
                self.activeAdSample!.quartile1 = 1;

            case AnalyticsAdQuartile.MIDPOINT:
                self.activeAdSample!.midpoint = 1;

            case AnalyticsAdQuartile.THIRD_QUARTILE:
                self.activeAdSample!.quartile3 = 1;
        }
    }
    
    private func resetActiveAd() {
        self.activeAdSample = nil
        self.currentTime = nil
    }
    
    private func completeAd(adBreak: AnalyticsAdBreak, adSample: AdSample, exitPosition: TimeInterval? = 0) {
        adSample.exitPosition = exitPosition
        adSample.timePlayed = exitPosition
        adSample.playPercentage = Util.calculatePercentageForTimeInterval(numerator: adSample.timePlayed, denominator: adSample.ad.duration, clamp: true)
        
        // reset startupTimestamp for the next ad, in case there are multiple ads in one ad break
        self.adStartupTimestamp = Date().timeIntervalSince1970
        self.isPlaying = false
        sendAnalyticsRequest(adBreak: adBreak, adSample: adSample)
        resetActiveAd()
    }
    
    private func getAdManifestDownloadTime(adBreak: AnalyticsAdBreak?) -> TimeInterval? {
        if (adBreak == nil || self.adManifestDownloadTimes[adBreak!.id] == nil) {
            return nil;
        }
        return self.adManifestDownloadTimes[adBreak!.id];
    }
    
    private func sendAnalyticsRequest(adBreak: AnalyticsAdBreak, adSample: AdSample? = nil) {
        guard let adapter = self.analytics.adapter else {
            return
        }
        
        let adEventData = AdEventData()
        
        adEventData.setEventData(eventData: adapter.createEventData())
        adEventData.setAdBreak(adBreak: adBreak);
        if let adSample = adSample {
            adEventData.setAdSample(adSample: adSample)
        }
        
        let moduleInfo = self.analytics.adAdapter?.getModuleInformation()
        if (moduleInfo != nil) {
            adEventData.adModule = moduleInfo?.name
            adEventData.adModuleVersion = moduleInfo?.version
        }
        
        if let manifestDownloadTime = getAdManifestDownloadTime(adBreak: adBreak){
            adEventData.manifestDownloadTime = Int64(manifestDownloadTime  * 1_000);
        }
        adEventData.autoplay = analytics.adAdapter?.isAutoPlayEnabled()
        adEventData.playerStartuptime = 1
        adEventData.time = Date().timeIntervalSince1970Millis
        adEventData.adImpressionId = NSUUID().uuidString
        
        self.analytics.sendAdEventData(adEventData: adEventData)
    }
}
