import CoreMedia
import Foundation

protocol PlayerAdapter {
    func createEventData() -> EventData
    func startMonitoring()
    func stopMonitoring()
    func destroy()
    func getDrmPerformanceInfo() -> DrmPerformanceInfo?
    var currentTime: CMTime? { get }
}
