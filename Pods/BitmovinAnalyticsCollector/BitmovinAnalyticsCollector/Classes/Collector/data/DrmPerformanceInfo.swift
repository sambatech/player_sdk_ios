import Foundation

public class DrmPerformanceInfo {
    var drmType: String?
    /// DRM download time in milliseconds
    var drmLoadTime: Int64?
    
    init(drmType: String) {
        self.drmType = drmType
    }

    init(drmType: String, drmLoadTime: Int64?) {
        self.drmType = drmType
        self.drmLoadTime = drmLoadTime
    }
}
