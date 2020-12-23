import Foundation

protocol EventDataDispatcher {
    func add(eventData: EventData)
    func addAd(adEventData: AdEventData)
    func enable()
    func disable()
    func clear()
}
