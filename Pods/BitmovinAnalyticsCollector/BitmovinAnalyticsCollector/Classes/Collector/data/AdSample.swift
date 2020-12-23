import Foundation

public class AdSample {
    var adStartupTime: TimeInterval?
    var clicked: Int = 0
    var clickPosition: TimeInterval?
    var closed: Int = 0
    var closePosition: TimeInterval?
    var completed: Int = 0
    var midpoint: Int?
    var percentageInViewport: Int?
    var quartile1: Int = 0
    var quartile3: Int = 0
    var skipped: Int = 0
    var skipPosition: TimeInterval?
    var started: Int = 0
    var timeHovered: TimeInterval?
    var timeInViewport: TimeInterval?
    var timePlayed: TimeInterval?
    var timeUntilHover: TimeInterval?
    var adPodPosition: Int?
    var exitPosition: TimeInterval?
    var playPercentage: Int?
    var skipPercentage: Int?
    var clickPercentage: Int?
    var closePercentage: Int?
    var errorPosition: TimeInterval?
    var errorPercentage: Int?
    var timeToContent: TimeInterval?
    var timeFromContent: TimeInterval?
    var manifestDownloadTime: TimeInterval?
    var errorCode: Int?
    var errorData: String?
    var errorMessage: String?
    var ad: AnalyticsAd = AnalyticsAd()
}
