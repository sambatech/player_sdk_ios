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

#import "GMFPlayerOverlayView.h"
#import "GMFResources.h"
#import "UIButton+GMFTintableButton.h"
#import "GMFTopBarView.h"
#import "UIImage+GMFTintableImage.h"


@implementation GMFPlayerOverlayView {
  UIActivityIndicatorView *_spinner;
  UIImageView *_image;
  UIImage *_playImage;
  UIImage *_pauseImage;
  UIImage *_replayImage;
  NSString *_playLabel;
  NSString *_pauseLabel;
  NSString *_replayLabel;
  UIButton *_playPauseReplayButton;
  UIColor *_currentColor;
  BOOL _isTopBarEnabled;
  CGRect _padding;
  CurrentPlayPauseReplayIcon _currentPlayPauseReplayIcon;
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _isTopBarEnabled = YES;
	_topBarHideEnabled = YES;
	_visible = YES;
    
    _image = [[UIImageView alloc] init];
    _image.backgroundColor = UIColor.clearColor;
    _image.hidden = YES;
    [self addSubview: _image];
      
    // Set the images.
    _playImage = [GMFResources playerBarPlayLargeButtonImage];
    _pauseImage = [GMFResources playerBarPauseLargeButtonImage];
    _replayImage = [GMFResources playerBarReplayLargeButtonImage];
	  
    // Set the button label strings (for accessibility).
    _playLabel = NSLocalizedStringFromTable(@"Play",
                                            @"GoogleMediaFramework",
                                            nil);
    _pauseLabel = NSLocalizedStringFromTable(@"Pause",
                                             @"GoogleMediaFramework",
                                             nil);
    _replayLabel = NSLocalizedStringFromTable(@"Replay",
                                              @"GoogleMediaFramework",
                                              nil);
    
    // Create the play/pause/replay button.
    _playPauseReplayButton = [[UIButton alloc] init];
    [self showPlayButton];
    [_playPauseReplayButton sizeToFit];
    [_playPauseReplayButton setShowsTouchWhenHighlighted:YES];
    [_playPauseReplayButton addTarget:self
                               action:@selector(didPressPlayPauseReplay:)
                     forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:_playPauseReplayButton];
    
    _spinner = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_spinner setUserInteractionEnabled:NO];
    [_spinner setIsAccessibilityElement:NO];
    [_spinner sizeToFit];
    [self addSubview:_spinner];

    // Player control bar
    //_playerControlsView = [[GMFPlayerControlsView alloc] initWithPadding:_padding];
	_playerControlsView = [[GMFPlayerControlsView alloc] init];
    [self setSeekbarTrackColorDefault];
    [self addSubview:_playerControlsView];
    
    _topBarView = [[GMFTopBarView alloc] init];
    //[_topBarView setLogoImage:[GMFResources playerBarPlayButtonImage]]; //SDK Samba customization
	
	[self addSubview:_topBarView];

    [self setupLayoutConstraints];
  }
  return self;
}

- (id)initWithControlsPadding:(CGRect)padding {
  _padding = padding;
  return [self init];
}

- (id)initWithControlsPadding:(CGRect)padding andFrame:(CGRect)frame {
	_padding = padding;
	return [self initWithFrame:frame];
}

- (void)setupLayoutConstraints {
  //[self setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_playerControlsView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_playPauseReplayButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_topBarView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_image setTranslatesAutoresizingMaskIntoConstraints:NO];

  NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_spinner,
                                                                 _playerControlsView,
                                                                 _topBarView);

  // Align spinner to the center X and Y.
  NSArray *constraints =
     [NSLayoutConstraint constraintsWithVisualFormat:@"|[_spinner]|"
                                             options:NSLayoutFormatAlignAllCenterX
                                             metrics:nil
                                               views:viewsDictionary];
  
  constraints = [constraints arrayByAddingObject:
                 [NSLayoutConstraint constraintWithItem:_playPauseReplayButton
                                              attribute:NSLayoutAttributeCenterY
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:_playPauseReplayButton.superview
                                              attribute:NSLayoutAttributeCenterY
                                             multiplier:1.0f
                                               constant:0]];
  
  constraints = [constraints arrayByAddingObject:
                 [NSLayoutConstraint constraintWithItem:_playPauseReplayButton
                                              attribute:NSLayoutAttributeCenterX
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:_playPauseReplayButton.superview
                                              attribute:NSLayoutAttributeCenterX
                                             multiplier:1.0f
                                               constant:0]];
  
  constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_image
                                                attribute:NSLayoutAttributeTrailing
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem: self
                                                attribute:NSLayoutAttributeTrailing
                                               multiplier:1.0f
                                                 constant:0]];
    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_image
                                                attribute:NSLayoutAttributeLeading
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem: self
                                                attribute:NSLayoutAttributeLeading
                                               multiplier:1.0f
                                                 constant:0]];

    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_image
                                                attribute:NSLayoutAttributeTop
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem: self
                                                attribute:NSLayoutAttributeTop
                                               multiplier:1.0f
                                                 constant:0]];
    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_image
                                                attribute:NSLayoutAttributeBottom
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem: self
                                                attribute:NSLayoutAttributeBottom
                                               multiplier:1.0f
                                                 constant:0]];
    
  // Technically this works with just the Y alignment, but xcode will complain about missing
  // constraints, so we add the X as well.
  constraints = [constraints arrayByAddingObject:
      [NSLayoutConstraint constraintWithItem:_spinner
                                   attribute:NSLayoutAttributeCenterY
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:_spinner.superview
                                   attribute:NSLayoutAttributeCenterY
                                  multiplier:1.0f
                                    constant:0]];
  constraints = [constraints arrayByAddingObject:
      [NSLayoutConstraint constraintWithItem:_spinner
                                   attribute:NSLayoutAttributeCenterX
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:_spinner.superview
                                   attribute:NSLayoutAttributeCenterX
                                  multiplier:1.0f
                                    constant:0]];


  // Align controlbar to the center bottom.
  NSDictionary *metrics = @{
      @"controlsBarHeight": @([_playerControlsView preferredHeight]),
      @"titleBarheight": @([_topBarView preferredHeight])
  };
  constraints = [constraints arrayByAddingObjectsFromArray:
      [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_playerControlsView(controlsBarHeight)]-%.0f-|", _padding.size.height]
                                              options:NSLayoutFormatAlignAllBottom
                                              metrics:metrics
                                                views:viewsDictionary]];
  constraints = [constraints arrayByAddingObjectsFromArray:
      [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_playerControlsView]|"
                                              options:NSLayoutFormatAlignAllBottom
                                              metrics:nil
                                                views:viewsDictionary]];
  
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_topBarView(titleBarheight)]"
                                                         options:NSLayoutFormatAlignAllTop
                                                         metrics:metrics
                                                           views:viewsDictionary]];
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_topBarView]|"
                                                         options:NSLayoutFormatAlignAllTop
                                                         metrics:nil
                                                           views:viewsDictionary]];
  
  
  [self addConstraints:constraints];
}

- (void)setDelegate:(id<GMFPlayerControlsViewDelegate>)delegate {
  _delegate = delegate;
  [_playerControlsView setDelegate:delegate];
}

- (void)showSpinner {
  if (_controlsOnly || !_visible) return;
  [_playPauseReplayButton setHidden:YES];
  [_spinner startAnimating];
  [_spinner setHidden:NO];
}

- (void)hideSpinner {
  if (_controlsOnly || !_visible) return;
  [_playPauseReplayButton setHidden:NO];
  [_spinner stopAnimating];
  [_spinner setHidden:YES];
}

- (void)setPlayerBarVisible:(BOOL)visible {
  if (_controlsOnly || !_visible) return;
  [_topBarView setAlpha:(_isTopBarEnabled && visible) ? 1 : !_topBarHideEnabled];
  [_playerControlsView setAlpha:visible ? 1 : 0];
  [_playPauseReplayButton setAlpha:visible ? 1 : 0];
	
  [self setNeedsLayout];
  [self layoutIfNeeded];
}

- (void)setControlsOnly:(BOOL)state {
  _controlsOnly = state;

    if (state) {
        [_playerControlsView setHidden:NO];
        [_playPauseReplayButton setHidden:state];
        [_spinner stopAnimating];
        [_spinner setHidden:state];
    }
  //[_topBarView setHidden:state];

  [self setNeedsLayout];
  [self layoutIfNeeded];
}

- (void)setVisible:(BOOL)state {
	_visible = state;
	
	[_playerControlsView setHidden:!state];
	[_playPauseReplayButton setHidden:!state];
	[_spinner stopAnimating];
	[_spinner setHidden:!state];
	[_topBarView setHidden:!state];
	
	[self setNeedsLayout];
	[self layoutIfNeeded];
}

-(void)showThumbAudioBackground {
    _image.hidden = NO;
}

-(void)hideThumbAudioBackground {
    _image.hidden = YES;
}

- (void)setThumbImageBackground:(UIImage *)image {
    _image.hidden = NO;
    _image.image = image;
}

- (void)disableTopBar {
  _isTopBarEnabled = NO;
  [_topBarView setAlpha:0];
}
- (void)enableTopBar {
  _isTopBarEnabled = YES;
  [_topBarView setAlpha:1];
}

- (void)setPlayPauseResetButtonBackgroundColor:(UIColor *)playPauseResetButtonBackgroundColor {
  _playPauseResetButtonBackgroundColor = playPauseResetButtonBackgroundColor;
  [_playPauseReplayButton setBackgroundColor:playPauseResetButtonBackgroundColor];
}

- (void)addActionButtonWithImage:(UIImage *)image
                            name:(NSString *)name
                          target:(id)target
                        selector:(SEL)selector {
  [_topBarView addActionButtonWithImage:image name:name target:target selector:selector];
}

- (UIButton *)getActionButton:(NSString *)name {
  return [_topBarView getActionButton:name];
}

- (void)removeActionButtonByName:(NSString *)name {
  [_topBarView removeActionButtonByName:name];
}

- (void)removeActionButton:(UIButton *)button {
  [_topBarView removeActionButton:button];
}

- (void)setVideoTitle:(NSString *)videoTitle {
  [_topBarView setVideoTitle:videoTitle];
}

- (void)setVideoTitlePosition:(NSString *)videoTitlePosition {
  [_topBarView setVideoTitlePosition:videoTitlePosition];
}

- (void)setLogoImage:(UIImage *)logoImage {
  [_topBarView setLogoImage:logoImage];
}

- (void)showPlayButton {
  [_playerControlsView setPlayButtonImage:[GMFResources playerBarPlayButtonImage]];

  if (_controlsOnly || !_visible) return;

  _currentPlayPauseReplayIcon = PLAY;
  [_playPauseReplayButton setImage:_playImage forState:UIControlStateNormal];
  [_playPauseReplayButton setAccessibilityLabel:_playLabel];
}

- (void)showPauseButton {
  [_playerControlsView setPlayButtonImage:[GMFResources playerBarPauseButtonImage]];

  if (_controlsOnly || !_visible) return;

  _currentPlayPauseReplayIcon = PAUSE;
  [_playPauseReplayButton setImage:_pauseImage forState:UIControlStateNormal];
  [_playPauseReplayButton setAccessibilityLabel:_pauseLabel];
}

- (void)showReplayButton {
  [_playerControlsView setPlayButtonImage:[GMFResources playerBarPlayButtonImage]];
	
  if (_controlsOnly || !_visible) {
	  [_playerControlsView setPlayButtonImage:[GMFResources playerBarReplayButtonImage]];
	  
	  return;
  }
  _currentPlayPauseReplayIcon = REPLAY;
  [_playPauseReplayButton setImage:_replayImage forState:UIControlStateNormal];
  [_playPauseReplayButton setAccessibilityLabel:_replayLabel];
}

- (void)setTotalTime:(NSTimeInterval)totalTime {
  [_playerControlsView setTotalTime:totalTime];
  [_playerControlsView updateScrubberAndTime];
}

- (void)setDownloadedTime:(NSTimeInterval)downloadedTime {
  [_playerControlsView setDownloadedTime:downloadedTime];
  [_playerControlsView updateScrubberAndTime];
}

- (void)setMediaTime:(NSTimeInterval)mediaTime {
  [_playerControlsView setMediaTime:mediaTime];
  [_playerControlsView updateScrubberAndTime];
}

- (void)setSeekbarTrackColor:(UIColor *)color {
  [_playerControlsView setSeekbarTrackColor:color];
}

- (void)setSeekbarTrackColorDefault {
  // Light blue]
	
  /*[_playerControlsView setSeekbarTrackColor:[UIColor colorWithRed:0.08235294117
                                                            green:0.49411764705
                                                             blue:0.98431372549
                                                            alpha:1.0]];*/
	[_playerControlsView setSeekbarTrackColor:_currentColor];
}

- (void)disableSeekbarInteraction {
  [_playerControlsView disableSeekbarInteraction];
}

- (void)enableSeekbarInteraction {
  [_playerControlsView enableSeekbarInteraction];
}

- (void)applyControlTintColor:(UIColor *)color { //SDK Samba customization
  // Tint the images for play, pause, and replay.
  //_playImage = [_playImage GMF_createTintedImage:color];
  //_pauseImage = [_pauseImage GMF_createTintedImage:color];
  //_replayImage = [_replayImage GMF_createTintedImage:color];
  
  // Tint the play/pause/replay button and the controls view.
  //[_playPauseReplayButton GMF_applyTintColor:color];
  _currentColor = color;
  
  //Change spinner color
  [_spinner setColor:_currentColor];
    
  [_playerControlsView applyControlTintColor:color];
}

- (void)didPressPlayPauseReplay:(id)sender {
  // Determine which icon the play/pause/replay button is showing and respond appropriately.
  switch (_currentPlayPauseReplayIcon) {
    case PLAY:
      [self.delegate didPressPlay];
      break;
    case REPLAY:
      [self.delegate didPressReplay];
      break;
    case PAUSE:
      [self.delegate didPressPause];
      break;
    default:
      break;
  }
}

// Check if the tap is over the subviews of the overlay, else let it go to handle taps
// in the aboveRenderingView
-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *hitView = [super hitTest:point withEvent:event];
  if (hitView == self) {
    return nil;
  }
  return hitView;
}

- (void)dealloc {
  [_playPauseReplayButton removeTarget:self
                                action:NULL
                      forControlEvents:UIControlEventTouchUpInside];
}

- (void)hideBackground {
	[_topBarView hideBackground];
}

- (void)showBackground {
	[_topBarView showBackground];
}

- (void)showPlayPauseReplayButton {
    [self addSubview:_playPauseReplayButton];
    
    NSArray *constraints = [[NSArray alloc] init];
    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_playPauseReplayButton
                                                attribute:NSLayoutAttributeCenterY
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:_playPauseReplayButton.superview
                                                attribute:NSLayoutAttributeCenterY
                                               multiplier:1.0f
                                                 constant:0]];
    
    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_playPauseReplayButton
                                                attribute:NSLayoutAttributeCenterX
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:_playPauseReplayButton.superview
                                                attribute:NSLayoutAttributeCenterX
                                               multiplier:1.0f
                                                 constant:0]];
    [self addConstraints:constraints];
}

- (void)hidePlayPauseReplayButton {
    [_playPauseReplayButton removeFromSuperview];
}

- (void)reset {
	[_topBarView reset];
}

@end

