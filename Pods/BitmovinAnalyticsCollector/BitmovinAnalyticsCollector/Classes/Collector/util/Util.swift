#if os(iOS)
import CoreTelephony
#endif

import AVKit
import Foundation

class Util {
    static func mainBundleIdentifier() -> String {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return "Unknown"
        }
        return bundleIdentifier
    }

    static func language() -> String {
        return Locale.current.identifier
    }

    static func userAgent() -> String {
        let model = UIDevice.current.model
        let product = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown Product"
        let scale = UIScreen.main.scale
        let height = UIScreen.main.bounds.size.height * scale
        let version = UIDevice.current.systemVersion
        #if os(iOS)
        let carrier = CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName ?? "Unknown Carrier"
        #elseif os(tvOS)
        let carrier = "Unknown Carrier tvOS"
        #else
        let carrier = "Unknown Carrier OSX"
        #endif

        let userAgent = String(format: "%@ / Apple; %@ %.f / iOS %@ / %@", product, model, height, version, carrier)

        return userAgent
    }

    static func version() -> String? {
        return Bundle(for: self).infoDictionary?["CFBundleShortVersionString"] as? String
    }

    static func timeIntervalToCMTime(_ timeInterval: TimeInterval) -> CMTime? {
        if !timeInterval.isNaN, !timeInterval.isInfinite {
            return CMTimeMakeWithSeconds(timeInterval, preferredTimescale: 1000)
        }
        return nil
    }

    static func toJson<T: Codable>(object: T?) -> String {
        let encoder = JSONEncoder()
        if #available(iOS 11.0, tvOS 11.0, *) {
            encoder.outputFormatting = [.sortedKeys]
        }

        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "Negative Infinity", nan: "nan")
        do {
            let jsonData = try encoder.encode(object)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                return ""
            }

            return jsonString
        } catch {
            return ""
        }
    }

    static func getUserId() -> String {
        let defaults = UserDefaults(suiteName: "com.bitmovin.analytics.collector_defaults")
        if let userIdFromStore = defaults?.string(forKey: "user_id") {
            return userIdFromStore
        }

        let newUserId = NSUUID().uuidString
        defaults?.set(newUserId, forKey: "user_id")
        return newUserId
    }

    static func getSupportedVideoCodecs() -> [String] {
        var codecs = ["avc"]
        if #available(iOS 11, tvOS 11, *) {
            codecs.append("hevc")
        }
        return codecs
    }

    static func streamType(from url: String) -> StreamType? {
        let path = url.lowercased()

        if path.hasSuffix(".m3u8") {
            return StreamType.hls
        }
        if path.hasSuffix(".mp4") || path.hasSuffix(".m4v") || path.hasSuffix(".m4a") || path.hasSuffix(".webm") {
            return StreamType.progressive
        }
        if path.hasSuffix(".mpd") {
            return StreamType.dash
        }
        return nil
    }
    
    static func getHostNameAndPath(uriString: String?) -> (String?, String?) {
        guard let uri = URL(string: uriString ?? "") else {
            return (nil, nil)
        }
        
        return (uri.host, uri.path)
    }
    
    static func calculatePercentage(numerator: Int64?, denominator: Int64?, clamp: Bool = false) -> Int? {
        if (denominator == nil || denominator == 0 || numerator == nil) {
            return nil;
        }
        let result = Int(Double(numerator!) / Double(denominator!) * 100)
        return clamp ? min(result, 100) : result;
    }
    
    static func calculatePercentageForTimeInterval(numerator: TimeInterval?, denominator: TimeInterval?, clamp: Bool = false) -> Int? {
        if (denominator == nil || denominator == 0 || numerator == nil) {
            return nil;
        }
        let result = Int(Double(numerator!) / Double(denominator!) * 100)
        return clamp ? min(result, 100) : result;
    }
}

extension Date {
    var timeIntervalSince1970Millis: Int64 {
        return Int64(round(Date().timeIntervalSince1970 * 1_000))
    }
}

extension TimeInterval {
    var milliseconds: Int64? {
        if self > Double(Int64.min) && self < Double(Int64.max) {
            return Int64(self * 1_000)
        }
        return nil
    }
}
