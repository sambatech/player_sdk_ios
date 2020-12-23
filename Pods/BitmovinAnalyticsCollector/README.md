# BitmovinAnalyticsCollector

Instruments adaptive streaming video players and collects information to be sent to the Bitmovin Analytics service.

To get started collecting data with Bitmovin Analytics you need a License-Key which you can get for free by signing up for a [free Bitmovin account](https://bitmovin.com/dashboard/signup).

## Support

### Platforms

* iOS 9.0+
* tvOS 9.0+

The DRM examples require iOS 11.2+.

### Video Players

* [Bitmovin Player](https://github.com/bitmovin/bitmovin-player-ios-sdk-cocoapod)
* AVPlayer

## Example

The following example creates a BitmovinAnalytics object and attaches an AVPlayer instance to it.

```swift
// Create a BitmovinAnalyticsConfig using your Bitmovin analytics license key and/or your Bitmovin Player Key
let config:BitmovinAnalyticsConfig = BitmovinAnalyticsConfig(key:"YOUR_ANALYTICS_KEY",playerKey:"YOUR_PLAYER_KEY")
let config:BitmovinAnalyticsConfig = BitmovinAnalyticsConfig(key:"YOUR_ANALYTICS_KEY")

// Create a AVPlayerCollector object using the config just created (for the Bitmovin Player, create a BitmovinPlayerCollector)
analyticsCollector = AVPlayerCollector(config: config);

// Attach your player instance
analyticsCollector.attachPlayer(player: player);

// Detach your player when you are done.
analyticsCollector.detachPlayer()
```

### Optional Configuration Parameters

```swift
config.cdnProvider = CdnProvider.akamai
config.customData1 = "customData1"
config.customData2 = "customData2"
config.customData3 = "customData3"
config.customData4 = "customData4"
config.customData5 = "customData5"
config.customerUserId = "customUserId"
config.experimentName = "experiement-1"
config.videoId = "iOSHLSStatic"
config.path = "/vod/breadcrumb/"
config.isLive = true
config.ads = true
```

A full example app can be seen [here](https://github.com/bitmovin/bitmovin-analytics-collector-ios/tree/develop/Example/BitmovinAnalyticsCollector).

## Installation

BitmovinAnalyticsCollector is available through [CocoaPods](http://cocoapods.org). We depend on `cocoapods` version `>= 1.4`. To install
it, simply add the following line to your Podfile:

### Bitmovin Player

The collector for the Bitmovin Player has a dependency on `BitmovinPlayer` version `>= 2.51.0`.

```ruby
  pod 'BitmovinAnalyticsCollector/Core', git: 'https://github.com/bitmovin/bitmovin-analytics-collector-ios.git', tag: '1.17.0'
  pod 'BitmovinAnalyticsCollector/BitmovinPlayer', git: 'https://github.com/bitmovin/bitmovin-analytics-collector-ios.git', tag: '1.17.0'
  source 'https://github.com/bitmovin/cocoapod-specs.git'
  pod 'BitmovinPlayer', '2.51.0'

  use_frameworks!
```

### AVPlayer

```ruby
pod 'BitmovinAnalyticsCollector/Core', git: 'https://github.com/bitmovin/bitmovin-analytics-collector-ios.git', tag: '1.17.0'
pod 'BitmovinAnalyticsCollector/AVPlayer', git: 'https://github.com/bitmovin/bitmovin-analytics-collector-ios.git', tag: '1.17.0'

use_frameworks!
```

To include all available collectors, add the following lines (the dependency on `BitmovinPlayer` applies here as well):

```ruby
pod 'BitmovinAnalyticsCollector', git: 'https://github.com/bitmovin/bitmovin-analytics-collector-ios.git', tag: '1.17.0'
source 'https://github.com/bitmovin/cocoapod-specs.git'
pod 'BitmovinPlayer', '2.51.0'

use_frameworks!
```

Then, in your command line run

```ruby
pod install
```

## Known Issues

* The `audioCodec` property is not collected at the moment, as the information isn't available in the player.
* `subtitleLanguage` will fallback to the `label`, if no language is defined.

## License

BitmovinAnalyticsCollector is available under the MIT license. See the LICENSE file for more info.

## Contributing

We are happy to accept contributions.
Upon opening a Pull Request you will be asked to sign a Contributor License Agreement.
