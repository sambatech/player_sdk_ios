// Copyright 2013 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "GMFVideoPlayer.h"
#import "GMFIMASDKAdService.h"

static const NSTimeInterval kGMFPollingInterval = 0.2;

static void *kGMFPlayerItemStatusContext = &kGMFPlayerItemStatusContext;
static void *kGMFPlayerRateContext = &kGMFPlayerRateContext;
static void *kGMFPlayerDurationContext = &kGMFPlayerDurationContext;
static void *kGMFPlayerErrorContext = &kGMFPlayerErrorContext;


static NSString * const kStatusKey = @"status";
static NSString * const kRateKey = @"rate";
static NSString * const kDurationKey = @"currentItem.duration";
static NSString * const kBufferEmptyKey = @"playbackBufferEmpty";
static NSString * const kLikelyToKeepUpKey = @"playbackLikelyToKeepUp";
static NSString * const kErrorKey = @"error";

// Pause the video if user unplugs their headphones.
/*void GMFAudioRouteChangeListenerCallback(void *inClientData,
                                         AudioSessionPropertyID inID,
                                         UInt32 inDataSize,
                                         const void *inData) {
  NSDictionary *routeChangeDictionary = (__bridge NSDictionary *)inData;
  NSString *reasonKey =
      [NSString stringWithCString:kAudioSession_AudioRouteChangeKey_Reason
                         encoding:NSASCIIStringEncoding];
  UInt32 reasonCode = 0;
  [[routeChangeDictionary objectForKey:reasonKey] getValue:&reasonCode];
  if (reasonCode == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
    // If the user removed the headphones, pause the playback.
    GMFVideoPlayer *_player = (__bridge GMFVideoPlayer *)inClientData;
    [_player pause];
  }
}*/

#pragma mark -
#pragma mark GMFPlayerLayerView

// GMFPlayerLayerView is a UIView that uses an AVPlayerLayer instead of CGLayer.
@interface GMFPlayerLayerView : UIView

// Returns an instance of GMFPlayerLayerView for rendering the video content in.
- (AVPlayerLayer *)playerLayer;

@end

@implementation GMFPlayerLayerView

+ (Class)layerClass {
  return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
  return (AVPlayerLayer *)[self layer];
}

@end

#pragma mark GMFVideoPlayer

@interface GMFVideoPlayer () {
  GMFPlayerLayerView *_renderingView;
}

// Polling timer for content time updates.
@property (nonatomic, strong) NSTimer *playbackStatusPoller;

// Track content time updates so we know when playback stalls or is paused/playing.
@property (nonatomic, assign) NSTimeInterval lastReportedPlaybackTime;

@property (nonatomic, assign) NSTimeInterval lastReportedBufferTime;

// Allow |[_player play]| to be called before content finishes loading.
@property (nonatomic, assign) BOOL pendingPlay;

// Set when pause is invoked and cleared when player enters the playing state.
// This is used to determine, when resuming from an audio interruption such as
// a phone call, whether the player should be resumed or it should stay in a
// pause state.
@property (nonatomic, assign) BOOL manuallyPaused;

// Creates an AVPlayerItem and AVPlayer instance when preparing to play a new content URL.
- (void)handlePlayableAsset:(AVAsset *)asset;

// Updates the current |player| and |playerItem| and removes and re-adds observers.
- (void)setAndObservePlayer:(AVPlayer *)player playerItem:(AVPlayerItem *)playerItem;

// Updates the current |playerItem| and removes and re-adds observers.
- (void)setAndObservePlayerItem:(AVPlayerItem *)playerItem;


// Starts a polling timer to track content playback state and time.
- (void)startPlaybackStatusPoller;

// Resets the above polling timer.
- (void)stopPlaybackStatusPoller;

// Handles audio session changes, such as when a user unplugs headphones.
- (void)onAudioSessionInterruption:(NSNotification *)notification;

// Handler for |playerItem| state changes.
- (void)playerItemStatusDidChange:(NSString*)keyPath;

// Reset the player state. Readies the player to play a new content URL.
- (void)clearPlayer;

// Resets the player to its default state.
- (void)reset;

@end

@implementation GMFVideoPlayer {
	CMTime _initialTime;
	CMTimeRange _currentRange;
}

// AVPlayerLayer class for video rendering.
@synthesize renderingView = _renderingView;

BOOL _assetReplaced = NO;

- (instancetype)init {
  self = [super init];
  if (self) {
    _state = kGMFPlayerStateEmpty;
    /*AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange,
                                    GMFAudioRouteChangeListenerCallback,
                                    (__bridge void *)self);*/
	  
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(audioHardwareRouteChanged:)
												 name:AVAudioSessionRouteChangeNotification
											   object:nil];
	
    // Handles interruptions to playback, like phone calls and activating Siri.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAudioSessionInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
	_backgroundColor = [UIColor blackColor];
	_initialTime = kCMTimeZero;
	_currentRange = kCMTimeRangeInvalid;
  }
  return self;
}

#pragma mark Public playback methods

- (void)play {
  _manuallyPaused = NO;
  if (_state == kGMFPlayerStateLoadingContent || _state == kGMFPlayerStateSeeking) {
    _pendingPlay = YES;
  } else if (![_player rate]) {
    _pendingPlay = YES;
    [_player play];
	[self setRate:_rate];
  }
}

- (void)pause {
  _pendingPlay = NO;
  _manuallyPaused = YES;
  if (_state == kGMFPlayerStatePlaying ||
      _state == kGMFPlayerStateBuffering ||
      _state == kGMFPlayerStateSeeking) {
    [_player pause];
    // Setting paused state here rather than KVO observing, since the |rate|
    // value can change to 0 because of buffer issues too.
    [self setState:kGMFPlayerStatePaused];
  }
}

- (void)replay {
  _pendingPlay = YES;
  [self seekToTime:0.0];
}

- (void)seekToTime:(NSTimeInterval)time {
  if ([_playerItem status] != AVPlayerItemStatusReadyToPlay) {
    // Calling [AVPlayerItem seekToTime:] before it is in the "ready to play" state
    // causes a crash.
    // TODO(tensafefrogs): Dev assert here instead of silent return.
    return;
  }

  CMTimeRange range = [self getCurrentSeekableTimeRange];

  // if invalid range, not a seekable media
  if (!CMTIMERANGE_IS_VALID(range))
	return;

  NSTimeInterval end = [GMFVideoPlayer secondsWithCMTime:CMTimeRangeGetEnd(range)];

  // must have an end
  if (end == 0)
	return;

  NSTimeInterval rangeStart = CMTimeGetSeconds(range.start);
  time += rangeStart;
  time = MIN(MAX(time, rangeStart), end);

  [self setState:kGMFPlayerStateSeeking];
  __weak GMFVideoPlayer *weakSelf = self;
  [_player seekToTime:CMTimeMakeWithSeconds(time, [_playerItem currentTime].timescale)
	  toleranceBefore:kCMTimeZero
	   toleranceAfter:kCMTimeZero
	completionHandler:^(BOOL finished) {
            GMFVideoPlayer *strongSelf = weakSelf;
            if (!strongSelf) {
              return;
            }
            if (finished) {
              if ([strongSelf pendingPlay]) {
                [[strongSelf player] play];
				[strongSelf setRate:_rate];
              } else {
                [strongSelf setState:kGMFPlayerStatePaused];
              }
            }
        }];
}

- (void)loadStreamWithAsset:(AVAsset*)asset {
  [self setState:kGMFPlayerStateLoadingContent];
  [self handlePlayableAsset:asset];
}

#pragma mark Querying Player for info

- (CMTimeRange)getCurrentSeekableTimeRange {
  NSValue *timeRange = [_playerItem seekableTimeRanges].lastObject;

  _currentRange = kCMTimeRangeZero;

  if (timeRange) {
	CMTimeRange range = kCMTimeRangeInvalid;
	[timeRange getValue:&range];
	_currentRange = CMTimeRangeEqual(range, kCMTimeRangeInvalid) ? kCMTimeRangeZero : range;
  }

  return _currentRange;
}

- (NSTimeInterval)currentMediaTime {
  if (![self isPlayableState])
	return 0.0;

  Float64 lastDuration = CMTimeGetSeconds(_currentRange.duration);

  [self getCurrentSeekableTimeRange];

  // notify duration changes
  if (CMTimeGetSeconds(_currentRange.duration) != lastDuration) {
	[self playerDurationDidChange];
  }

  return [GMFVideoPlayer secondsWithCMTime:CMTimeSubtract([_playerItem currentTime],
														  CMTIME_IS_NUMERIC(_currentRange.start) ?
														  _currentRange.start : kCMTimeZero)];
}

- (NSTimeInterval)totalMediaTime {
  [self getCurrentSeekableTimeRange];
  return [GMFVideoPlayer secondsWithCMTime:CMTIME_IS_NUMERIC(_currentRange.duration) ?
		  _currentRange.duration : [_playerItem duration]];
}

- (NSTimeInterval)bufferedMediaTime {
  if ([self isPlayableState]) {
    // Call |loadedTimeRanges| before storing |currentTime| so that the
    // loaded time ranges don't change before we get |currentTime|.
    // This can happen while video is playing.
    NSArray *timeRanges = [_playerItem loadedTimeRanges];
    CMTime currentTime = [_playerItem currentTime];
    for (NSValue *timeRange in timeRanges) {
      CMTimeRange range;
      [timeRange getValue:&range];
      if (CMTimeRangeContainsTime(range, currentTime)) {
        return [GMFVideoPlayer secondsWithCMTime:CMTimeRangeGetEnd(range)];
      }
    }
  }
  return 0;
}

- (BOOL)isLive {
  // |totalMediaTime| is 0 if the video is a live stream.
  // TODO(tensafefrogs): Is there a better way to determine if the video is live?
  return [GMFVideoPlayer secondsWithCMTime:[_playerItem duration]] == 0.0;
}

#pragma mark Private methods

// Once an asset is playable (i.e. tracks are loaded) hand it off to this method to add observers.
- (void)handlePlayableAsset:(AVAsset *)asset {
  AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
  // Recreating the AVPlayer instance because of issues when playing HLS then non-HLS back to
  // back, and vice-versa.
  AVPlayer *player = _player;
	
  if (player) {
	[self setAndObservePlayerItem:playerItem];
	[player replaceCurrentItemWithPlayerItem:playerItem];
	_assetReplaced = YES;
  }
  else {
	player = [AVPlayer playerWithPlayerItem:playerItem];
	[self setAndObservePlayer:player playerItem:playerItem];
  }
}

- (void)setAndObservePlayerItem:(AVPlayerItem *)playerItem {
	// Player item observers.
	[_playerItem removeObserver:self forKeyPath:kStatusKey];
	[_playerItem removeObserver:self forKeyPath:kBufferEmptyKey];
	[_playerItem removeObserver:self forKeyPath:kLikelyToKeepUpKey];
	[_playerItem removeObserver:self forKeyPath:kErrorKey];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:AVPlayerItemDidPlayToEndTimeNotification
												  object:_playerItem];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
												 name:AVPlayerItemPlaybackStalledNotification
											   object:_playerItem];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
												 name:AVPlayerItemFailedToPlayToEndTimeNotification
											   object:_playerItem];
	
	_playerItem = playerItem;
	if (_playerItem) {
		[_playerItem addObserver:self
					  forKeyPath:kStatusKey
						 options:0
						 context:kGMFPlayerItemStatusContext];
		
		[_playerItem addObserver:self
					  forKeyPath:kBufferEmptyKey
						 options:NSKeyValueObservingOptionNew
						 context:kGMFPlayerItemStatusContext];
		
		[_playerItem addObserver:self
					  forKeyPath:kLikelyToKeepUpKey
						 options:NSKeyValueObservingOptionNew
						 context:kGMFPlayerItemStatusContext];
		
		[_playerItem addObserver:self
					  forKeyPath:kErrorKey
						 options:NSKeyValueObservingOptionNew
						 context:kGMFPlayerErrorContext];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playbackStallHandler:)
													 name:AVPlayerItemPlaybackStalledNotification
												   object:_playerItem];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playbackStallHandler:)
													 name:AVPlayerItemFailedToPlayToEndTimeNotification
												   object:_playerItem];
		__weak GMFVideoPlayer *weakSelf = self;
		[[NSNotificationCenter defaultCenter]
		 addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
		 object:_playerItem
		 queue:[NSOperationQueue mainQueue]
		 usingBlock:^(NSNotification *note) {
			 GMFVideoPlayer *strongSelf = weakSelf;
			 if (!strongSelf) {
				 return;
			 }
			 [strongSelf playbackDidReachEnd];
		 }];
	}
}
- (void)playbackStallHandler:(NSNotification *)notification {
  self.error = [NSError errorWithDomain:@"player_item" code:NSURLErrorNotConnectedToInternet userInfo:nil];
  [self setState:kGMFPlayerStateError];
}
- (void)setAndObservePlayer:(AVPlayer *)player playerItem:(AVPlayerItem *)playerItem {
  [self setAndObservePlayerItem:playerItem];
	
  // Player observers.
  [_player removeObserver:self forKeyPath:kRateKey];
  [_player removeObserver:self forKeyPath:kDurationKey];

  _player = player;
  if (_player) {
    [_player addObserver:self
              forKeyPath:kRateKey
                 options:0
                 context:kGMFPlayerRateContext];
    [_player addObserver:self
              forKeyPath:kDurationKey
                 options:0
                 context:kGMFPlayerDurationContext];
    _renderingView = [[GMFPlayerLayerView alloc] init];
    [[_renderingView playerLayer] setVideoGravity:AVLayerVideoGravityResizeAspect];
	[self setBackgroundColor: _backgroundColor];
    [[_renderingView playerLayer] setPlayer:_player];
  } else {
    // It is faster to discard the rendering view and create a new one when
    // necessary than to call setPlayer:nil and reuse it for future playbacks.
    _renderingView = nil;
  }
}

- (void)switchAsset:(AVAsset*)asset {
	if (!_player) return;
	
	_initialTime = _player.currentTime;
	
	[self handlePlayableAsset:asset];
}

- (void)setState:(GMFPlayerState)state {
  if (state != _state) {
    GMFPlayerState prevState = _state;
    _state = state;

    // Call this last in case the delegate removes references/destroys self.
    [_delegate videoPlayer:self stateDidChangeFrom:prevState to:state];
  }
}

- (void)setBackgroundColor:(UIColor*)backgroundColor {
	if (_renderingView == nil) {
		_backgroundColor = backgroundColor;
		return;
	}
	
	[[_renderingView playerLayer] setBackgroundColor:[backgroundColor CGColor]];
}

- (void)setRate:(float)rate {
	if (rate == _player.rate || rate == 0)
	  return;
	
	// values greater than 2 must be checked
	if (rate > 2) {
	  if (!_playerItem.canPlayFastForward)
		return;
	}
	// values less than -1 must be checked
	else if (rate < -1 && !(_playerItem.canPlayReverse &&
	  _playerItem.canPlayFastReverse))
	  return;

	_rate = rate;

    if (_state == kGMFPlayerStatePlaying || _state == kGMFPlayerStateBuffering || _state == kGMFPlayerStateSeeking)[_player setRate:rate];
}

- (void)startPlaybackStatusPoller {
  if (_playbackStatusPoller) {
    return;
  }
  _playbackStatusPoller = [NSTimer
      scheduledTimerWithTimeInterval:kGMFPollingInterval
                              target:self
                            selector:@selector(updateStateAndReportMediaTimes)
                            userInfo:nil
                             repeats:YES];
  // Ensure timer fires during UI events such as scrolling.
  [[NSRunLoop currentRunLoop] addTimer:_playbackStatusPoller
                               forMode:NSRunLoopCommonModes];
}

- (void)stopPlaybackStatusPoller {
  _lastReportedBufferTime = 0;
  [_playbackStatusPoller invalidate];
  _playbackStatusPoller = nil;
}

#pragma mark AVAudioSession notifications

- (void)onAudioSessionInterruption:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  AVAudioSessionInterruptionType type =
      [(NSNumber *)[userInfo valueForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
  NSUInteger flags =
      [(NSNumber *)[userInfo valueForKey:AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
  // It seems like we don't receive the InterruptionTypeBegan
  // event properly. This might be an iOS bug:
  // http://openradar.appspot.com/12412685
  //
  // So instead we try to detect if the player was manually paused by invoking
  // pause, and only resume if the player was not manually paused.
  if (type == AVAudioSessionInterruptionTypeEnded &&
      flags & AVAudioSessionInterruptionOptionShouldResume &&
      _state == kGMFPlayerStatePaused &&
      !_manuallyPaused) {
    [self play];
  }
}

- (void)audioHardwareRouteChanged:(NSNotification *)notification {
	NSInteger routeChangeReason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
	if (routeChangeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
		[self pause];
	}
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  /*AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange,
                                                 GMFAudioRouteChangeListenerCallback,
                                                 (__bridge void *)self);*/
  [self clearPlayer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  //[NSString stringWithFormat:@"%@: rate=%d likelyToKeepUp=%f bufferEmpty=%d error=%@; %@", keyPath, [_player rate], [_playerItem isPlaybackLikelyToKeepUp], [_playerItem isPlaybackBufferEmpty], [_playerItem error], [_playerItem errorLog]]
  if (context == kGMFPlayerDurationContext) {
    // Update total duration of player
   [self playerDurationDidChange];
  } else if (context == kGMFPlayerItemStatusContext) {
	[self playerItemStatusDidChange:keyPath];
  } else if (context == kGMFPlayerRateContext) {
    [self playerRateDidChange];
  } else if (context == kGMFPlayerErrorContext) {
	self.error = _playerItem.error;
	[self setState:kGMFPlayerStateError];
  } else {
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
  }
}

- (void)playerItemStatusDidChange:(NSString*)keyPath {
  if ([_playerItem status] == AVPlayerItemStatusReadyToPlay &&
      _state == kGMFPlayerStateLoadingContent) {
    // TODO(tensafefrogs): It seems like additional AVPlayerItemStatusReadyToPlay
    // events indicate HLS stream switching. Investigate.
    [self setState:kGMFPlayerStateReadyToPlay];
    if (_pendingPlay) {
      // Let's buffer some more data and let the playback poller start playback.
      [self setState:kGMFPlayerStateBuffering];
      [self startPlaybackStatusPoller];
    } else {
      [self setState:kGMFPlayerStatePaused];
    }
  }
  // playback got stalled
  else if (keyPath == kBufferEmptyKey &&
		   ((int)[self currentMediaTime]) > 0 &&
		   _playerItem.isPlaybackBufferEmpty &&
		   !_playerItem.isPlaybackLikelyToKeepUp &&
		   _player.rate == 0) {
	  // test network/internet connection
	  NSURLSessionDataTask* dataTask = [[NSURLSession sharedSession] dataTaskWithURL:((AVURLAsset*)[_playerItem asset]).URL
								  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		  if (error == nil || self.error != nil) return;
		  
		  self.error = [NSError errorWithDomain:@"player_item" code:NSURLErrorNotConnectedToInternet userInfo:nil];
		  [self setState:kGMFPlayerStateError];
	  }];
	  [dataTask resume];
  }
  // able to play new asset
  else if (keyPath == kLikelyToKeepUpKey) {
	  if (_playerItem.isPlaybackLikelyToKeepUp)
		  self.error = nil;
	  
	  if (_assetReplaced) {
		_assetReplaced = NO;
		
		float secs = CMTimeGetSeconds(_initialTime);
		
		if (secs > 0)
		  [self seekToTime:secs];
		else {
		  [_player play];
		  [self setRate:_rate];
		}
	  }
  }
  // fail state
  else if ([_playerItem status] == AVPlayerItemStatusFailed) {
    // TODO(tensafefrogs): Better error handling: [self failWithError:[_playerItem error]];
	self.error = _playerItem.error;
	[self setState:kGMFPlayerStateError];
  }
}

- (void)playerRateDidChange {
  // TODO(tensafefrogs): Abandon rate observing since it's inconsistent between HLS
  // and non-HLS videos. Rely on the poller.
  if ([_player rate]) {
    [self startPlaybackStatusPoller];
    [self setState:kGMFPlayerStatePlaying];
  }
  // rate notification when rate=0 means media isn't playing
  /*else if (CMTimeGetSeconds(_playerItem.currentTime) < CMTimeGetSeconds(_playerItem.duration)) {
	self.error = [NSError errorWithDomain:@"player_item" code:NSURLErrorNotConnectedToInternet userInfo:nil];
	[self setState:kGMFPlayerStateError];
  }*/
}

- (void)playerDurationDidChange {
  NSTimeInterval currentTotalTime = [self totalMediaTime];
  [_delegate videoPlayer:self currentTotalTimeDidChangeToTime:currentTotalTime];
}

- (void)playbackDidReachEnd {
  if ([_playerItem status] != AVPlayerItemStatusReadyToPlay) {
    // In some cases, |AVPlayerItemDidPlayToEndTimeNotification| is fired while
    // the player is being initialized. Ignore such notifications.
    return;
  }

  // Make sure we report the final media time if necessary before stopping the poller.
  [self updateStateAndReportMediaTimes];
  [self stopPlaybackStatusPoller];
  [self setState:kGMFPlayerStateFinished];
  // For HLS videos, the rate isn't set to 0 on video end, so we have to do it
  // explicitly.
  if ([_player rate]) {
    [_player setRate:0];
  }
}

- (BOOL)isPlayableState {
  // TODO(tensafefrogs): Drop this method and rely on the existence of |_player|.
  return _state == kGMFPlayerStatePlaying ||
      _state == kGMFPlayerStatePaused ||
      _state == kGMFPlayerStateReadyToPlay ||
      _state == kGMFPlayerStateBuffering ||
      _state == kGMFPlayerStateSeeking ||
      _state == kGMFPlayerStateFinished;
}

- (void)updateStateAndReportMediaTimes {
  NSTimeInterval bufferedMediaTime = [self bufferedMediaTime];
  if (_lastReportedBufferTime != bufferedMediaTime) {
    _lastReportedBufferTime = bufferedMediaTime;
    [_delegate videoPlayer:self bufferedMediaTimeDidChangeToTime:bufferedMediaTime];
  }

  if (_state != kGMFPlayerStatePlaying && _state != kGMFPlayerStateBuffering) {
    return;
  }

  NSTimeInterval currentMediaTime = [self currentMediaTime];
  // If the current media time is different from the last reported media time,
  // the player is playing.
  if (_lastReportedPlaybackTime != currentMediaTime) {
    _lastReportedPlaybackTime = currentMediaTime;
    if (_state == kGMFPlayerStatePlaying) {
      [_delegate videoPlayer:self currentMediaTimeDidChangeToTime:currentMediaTime];
    } else {
      // Player resumed playback from buffering state.
      [self setState:kGMFPlayerStatePlaying];
    }
  } else if (![_player rate]) {
    [_player play];
	[self setRate:_rate];
  }
}

#pragma mark Cleanup

- (void)clearPlayer {
  _pendingPlay = NO;
  _manuallyPaused = NO;
  [self stopPlaybackStatusPoller];
  [_player pause];
    [_player replaceCurrentItemWithPlayerItem:nil];
  [self setAndObservePlayer:nil playerItem:nil];
  _lastReportedPlaybackTime = 0;
  _lastReportedBufferTime = 0;
}

- (void)reset {
  [self clearPlayer];
  [self setState:kGMFPlayerStateEmpty];
}

- (void)destroyInternal {
    if (_player != nil) {
        [_player replaceCurrentItemWithPlayerItem:nil];
    }
}

#pragma mark Utils and Misc.

+ (NSTimeInterval)secondsWithCMTime:(CMTime)t {
  return CMTIME_IS_NUMERIC(t) ? CMTimeGetSeconds(t) : 0;
}

@end


