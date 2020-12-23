import AVKit
import Foundation

public class AVPlayerCollector: BitmovinAnalyticsInternal {

    public override init(config: BitmovinAnalyticsConfig) {
        super.init(config: config)
    }

    /**
     * Attach a player instance to this analytics plugin. After this is completed, BitmovinAnalytics
     * will start monitoring and sending analytics data based on the attached player instance.
     */
    public func attachPlayer(player: AVPlayer) {
        attach(adapter: AVPlayerAdapter(player: player, config: config, stateMachine: stateMachine), autoplay: false)
    }
}
