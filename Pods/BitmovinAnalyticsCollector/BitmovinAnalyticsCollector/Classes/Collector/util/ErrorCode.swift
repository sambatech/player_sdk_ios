import Foundation

struct ErrorCode {
    let code: Int
    let message: String
    
    static let ANALYTICS_QUALITY_CHANGE_THRESHOLD_EXCEEDED = ErrorCode(code: 10000, message: "ANALYTICS_QUALITY_CHANGE_THRESHOLD_EXCEEDED")
    static let ANALYTICS_BUFFERING_TIMEOUT_REACHED = ErrorCode(code: 10001, message: "ANALYTICS_BUFFERING_TIMEOUT_REACHED")
    
    var data: [String: Any] {
        return [BitmovinAnalyticsInternal.ErrorCodeKey: code,
                BitmovinAnalyticsInternal.ErrorMessageKey: message]
    }
}
