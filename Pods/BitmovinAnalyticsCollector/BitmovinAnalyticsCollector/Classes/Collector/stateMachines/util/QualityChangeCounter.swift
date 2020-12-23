import Foundation

public class QualityChangeCounter {
    private static var kAnalyticsQualityChangeThreshold = 50
    private static var kAnalyticsQualityChangeResetIntervalSeconds: TimeInterval = 60 * 60
    private static var kAnalyticsQualityChangeIntervalId = "com.bitmovin.analytics.core.utils.QualityChangeCounter"
     
    private var qualityResetWorkItem: DispatchWorkItem?
    private var qualityChangeCounter = 0
    
    func startInterval() {
        resetInterval()
        qualityResetWorkItem = DispatchWorkItem {
            self.qualityChangeCounter = 0
        }
        
        DispatchQueue.init(label: QualityChangeCounter.kAnalyticsQualityChangeIntervalId).asyncAfter(deadline: .now() + QualityChangeCounter.kAnalyticsQualityChangeResetIntervalSeconds, execute: qualityResetWorkItem!)
    }
    
    func resetInterval() {
        if (qualityResetWorkItem == nil) {
            return
        }
        
        qualityResetWorkItem?.cancel()
        qualityResetWorkItem = nil
    }
    
    func increaseCounter() {
        if (qualityChangeCounter == 0) {
            startInterval()
        }
        qualityChangeCounter += 1
    }
    
    func isQualityChangeEnabled() -> Bool {
        return qualityChangeCounter <= QualityChangeCounter.kAnalyticsQualityChangeThreshold
    }
}
