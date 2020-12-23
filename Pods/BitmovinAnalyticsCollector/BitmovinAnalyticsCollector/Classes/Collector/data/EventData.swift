import Foundation

public class EventData: Codable {
    var domain: String
    var path: String?
    var language: String
    var userAgent: String?
    var errorCode: Int?
    var errorMessage: String?
    var errorData: String?
    var screenWidth: Int?
    var screenHeight: Int?
    var isLive: Bool = false
    var isCasting: Bool? = false
    var isMuted: Bool? = false
    var videoDuration: Int64 = 0
    var time: Double?
    var videoWindowWidth: Int = 0
    var videoWindowHeight: Int = 0
    var droppedFrames: Int = 0
    var played: Int64 = 0
    var buffered: Int64 = 0
    var paused: Int64 = 0
    var ad: Int64 = 0
    var seeked: Int64 = 0
    var videoPlaybackWidth: Int?
    var videoPlaybackHeight: Int?
    var videoBitrate: Double = 0
    var audioBitrate: Double = 0
    var videoTimeStart: Int64 = 0
    var videoTimeEnd: Int64 = 0
    var videoStartupTime: Int64 = 0
    var duration: Int64 = 0
    var startupTime: Int64 = 0
    var analyticsVersion: String = "0"
    var key: String?
    var playerKey: String?
    var player: String?
    var playerTech: String?
    var cdnProvider: String?
    var streamFormat: String?
    var videoId: String?
    var videoTitle: String?
    var customUserId: String?
    var customData1: String?
    var customData2: String?
    var customData3: String?
    var customData4: String?
    var customData5: String?
    var customData6: String?
    var customData7: String?
    var experimentName: String?
    var userId: String?
    var impressionId: String
    var state: String?
    var m3u8Url: String?
    var mpdUrl: String?
    var progUrl: String?
    var playerStartupTime: Int64 = 0
    var pageLoadType: Int = 1
    var pageLoadTime: Int64 = 0
    var version: String?
    var sequenceNumber: Int32 = 0
    var drmType: String?
    var drmLoadTime: Int64?
    #if os(iOS)
    var platform: String = "iOS"
    #elseif os(tvOS)
    var platform: String = "tvOS"
    #elseif os(watchOS)
    var platform: String = "watchOS"
    #elseif os(macOS)
    var platform: String = "macOS"
    #elseif os(Linux)
    var platform: String = "Linux"
    #else
    var platform: String = "unknown"
    #endif
    var videoCodec: String?
    var audioCodec: String?
    var supportedVideoCodecs: [String]?
    var subtitleEnabled: Bool?
    var subtitleLanguage: String?
    var audioLanguage: String?
    var videoStartFailed: Bool?
    var videoStartFailedReason: String?

    public init(config: BitmovinAnalyticsConfig, impressionId: String) {
        domain = Util.mainBundleIdentifier()
        userId = Util.getUserId()

        if let text = Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"] as? String {
            analyticsVersion = text
        }

        version = UIDevice.current.systemVersion
        language = Util.language()
        userAgent = Util.userAgent()
        self.impressionId = impressionId
        key = config.key
        playerKey = config.playerKey
        cdnProvider = config.cdnProvider
        customUserId = config.customerUserId
        customData1 = config.customData1
        customData2 = config.customData2
        customData3 = config.customData3
        customData4 = config.customData4
        customData5 = config.customData5
        customData6 = config.customData6
        customData7 = config.customData7
        videoId = config.videoId
        videoTitle = config.title
        experimentName = config.experimentName
        path = config.path
    }

    public func jsonString() -> String {
        let encoder = JSONEncoder()
        if #available(iOS 11.0, tvOS 11.0, *) {
            encoder.outputFormatting = [.sortedKeys]
        }

        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "Negative Infinity", nan: "nan")
        do {
            let jsonData = try encoder.encode(self)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                return ""
            }

            return jsonString
        } catch {
            return ""
        }
    }
}
