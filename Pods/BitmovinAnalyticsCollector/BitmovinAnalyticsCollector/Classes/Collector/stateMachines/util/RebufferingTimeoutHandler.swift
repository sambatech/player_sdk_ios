import Foundation

public class RebufferingTimeoutHandler {
    private static var kAnalyticsRebufferingTimeoutIntervalId = "com.bitmovin.analytics.core.utils.RebufferingTimeoutHandler"
    private static var kAnalyticsRebufferingTimeoutSeconds: TimeInterval = 2 * 60
    
    private var rebufferingTimeoutWorkItem: DispatchWorkItem?
    private var stateMachine: StateMachine?
    
    func initialise(stateMachine: StateMachine) {
        self.stateMachine = stateMachine
    }
    
    func startInterval() {
        resetInterval()
        rebufferingTimeoutWorkItem = DispatchWorkItem {
            self.stateMachine?.transitionState(destinationState: .error, time: self.stateMachine?.delegate?.currentTime, data: ErrorCode.ANALYTICS_BUFFERING_TIMEOUT_REACHED.data)
            self.resetInterval()
        }

        DispatchQueue.init(label: RebufferingTimeoutHandler.kAnalyticsRebufferingTimeoutIntervalId).asyncAfter(deadline: .now() + RebufferingTimeoutHandler.kAnalyticsRebufferingTimeoutSeconds, execute: rebufferingTimeoutWorkItem!)
    }

    func resetInterval() {
        if (rebufferingTimeoutWorkItem == nil) {
            return
        }

        rebufferingTimeoutWorkItem?.cancel()
        rebufferingTimeoutWorkItem = nil
    }
}
