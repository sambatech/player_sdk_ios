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

#import "GMFPlayerControlsView.h"
#import "GMFResources.h"
#import "UILabel+GMFLabels.h"
#import "UIButton+GMFTintableButton.h"

static const CGFloat kGMFBarPaddingX = 8;

@implementation GMFPlayerControlsView {
  UIImageView *_backgroundView;
  UIButton *_minimizeButton;
  UIButton *_hdButton;
  UIButton *_playButton;
  UIButton *_playerReplayButton;
  UILabel *_secondsPlayedLabel;
  UILabel *_totalSecondsLabel;
  UILabel *_timeSeparator; // Samba SDK Player
  UISlider *_scrubber;
  NSTimeInterval _totalSeconds;
  NSTimeInterval _mediaTime;
  NSTimeInterval _downloadedSeconds;
  NSLayoutConstraint* _hdHideConstraint;
  NSLayoutConstraint* _playHideConstraint;
  NSLayoutConstraint* _minimizeHideConstraint;
  NSLayoutConstraint* _scrubberRightConstraint;
  BOOL _userScrubbing;
  CGRect _padding;

  __weak id<GMFPlayerControlsViewDelegate> _delegate;
}

// TODO(tensafefrogs): Add _secondsPlayedLabel / _totalSecondsLabel to controls
- (id)init {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _backgroundView = [[UIImageView alloc] initWithImage:[GMFResources playerBarBackgroundImage]];
    [self addSubview:_backgroundView];

    _secondsPlayedLabel = [UILabel GMF_clearLabelForPlayerControls];
    [_secondsPlayedLabel setFont:[UIFont fontWithName:@"Arial" size:14.0]]; //Samba SDK Player
    [_secondsPlayedLabel setTextAlignment:NSTextAlignmentCenter];
    [_secondsPlayedLabel setIsAccessibilityElement:NO];
    [self addSubview:_secondsPlayedLabel];

    _totalSecondsLabel = [UILabel GMF_clearLabelForPlayerControls];
    [_totalSecondsLabel setFont:[UIFont fontWithName:@"Arial" size:14.0]];
    [_totalSecondsLabel setIsAccessibilityElement:NO];
    [self addSubview:_totalSecondsLabel];
	  
	//Separator //Samba SDK Player
	_timeSeparator = [UILabel GMF_clearLabelForPlayerControls];
	[_timeSeparator setFont:[UIFont fontWithName:@"Arial" size:14.0]];
	[_timeSeparator setTextAlignment:NSTextAlignmentCenter];
	[_timeSeparator setIsAccessibilityElement:NO];
	[_timeSeparator setText:@"/"];
	[self addSubview:_timeSeparator];

    // Seekbar
    _scrubber = [[UISlider alloc] init];
    [_scrubber setMinimumValue:0.0];
    [_scrubber setAccessibilityLabel:
        NSLocalizedStringFromTable(@"Seek bar", @"GoogleMediaFramework", nil)];
    [self setSeekbarThumbToDefaultImage];
    [_scrubber setMaximumTrackTintColor:[UIColor colorWithWhite:122/255.0 alpha:1.0]];
    [_scrubber addTarget:self
                  action:@selector(didScrubbingProgress:)
        forControlEvents:UIControlEventValueChanged];
    // Scrubbing starts as soon as the user touches the scrubber.
    [_scrubber addTarget:self
                  action:@selector(didScrubbingStart:)
        forControlEvents:UIControlEventTouchDown];
    [_scrubber addTarget:self
                  action:@selector(didScrubbingEnd:)
        forControlEvents:UIControlEventTouchUpInside];
    [_scrubber addTarget:self
                  action:@selector(didScrubbingEnd:)
        forControlEvents:UIControlEventTouchUpOutside];
    [self addSubview:_scrubber];
	  
	  _playButton = [self playerButtonWithImage:[GMFResources playerBarPlayButtonImage]
									   action:@selector(didPressPlay:)
						   accessibilityLabel:
				   NSLocalizedStringFromTable(@"Play/Pause",
											  @"GoogleMediaFramework",
											  nil)];
	  
	  
	  _playHideConstraint = [NSLayoutConstraint constraintWithItem:_playButton
													   attribute:NSLayoutAttributeWidth
													   relatedBy:NSLayoutRelationEqual
														  toItem:nil
													   attribute:NSLayoutAttributeNotAnAttribute
													  multiplier:1.0f
														constant:0];
	
	  _hdButton = [self playerButtonWithImage:[GMFResources playerBarHdButtonImage]
									   action:@selector(didPressHd:)
						   accessibilityLabel:
				   NSLocalizedStringFromTable(@"Output",
											  @"GoogleMediaFramework",
											  nil)];
	  
	  _hdHideConstraint = [NSLayoutConstraint constraintWithItem:_hdButton
													   attribute:NSLayoutAttributeWidth
													   relatedBy:NSLayoutRelationEqual
														  toItem:nil
													   attribute:NSLayoutAttributeNotAnAttribute
													  multiplier:1.0f
														constant:0];
	  
	_minimizeButton = [self playerButtonWithImage:[GMFResources playerBarMinimizeButtonImage]
										 action:@selector(didPressMinimize:)
							 accessibilityLabel:
					 NSLocalizedStringFromTable(@"Minimize",
												@"GoogleMediaFramework",
												nil)];
	  
	  _minimizeHideConstraint = [NSLayoutConstraint constraintWithItem:_minimizeButton
													   attribute:NSLayoutAttributeWidth
													   relatedBy:NSLayoutRelationEqual
														  toItem:nil
													   attribute:NSLayoutAttributeNotAnAttribute
													  multiplier:1.0f
															  constant:0];
	
	[self addSubview:_playButton];
	[self addSubview:_hdButton];
	[self addSubview:_minimizeButton];

    [self setupLayoutConstraints];
	  
	[self hidePlayButton];
	[self hideHdButton];
  }
  return self;
}

- (id)initWithPadding:(CGRect)padding {
  _padding = padding;
  return [self init];
}

- (void)setPlayButtonImage:(UIImage*)image {
	[_playButton setImage:image forState:UIControlStateNormal];
}

- (void)setMinimizeButtonImage:(UIImage*)image {
	[_minimizeButton setImage:image forState:UIControlStateNormal];
}

- (void)hidePlayButton {
	[self addConstraint:_playHideConstraint];
}

- (void)showPlayButton {
	[self removeConstraint:_playHideConstraint];
}

- (void)hideHdButton {
	[self addConstraint:_hdHideConstraint];
}

- (void)showHdButton {
	[self removeConstraint:_hdHideConstraint];
}

- (void)hideFullscreenButton {
	[self addConstraint:_minimizeHideConstraint];
	[self removeConstraint:_scrubberRightConstraint];
	_scrubberRightConstraint.constant = 0;
	[self addConstraint:_scrubberRightConstraint];
}

- (void)hideScrubber {
	_scrubber.hidden = YES;
}

- (void)hideTotalTime {
	_totalSecondsLabel.hidden = YES;
	_timeSeparator.hidden = YES;
}

- (void)showFullscreenButton {
	[self removeConstraint:_minimizeHideConstraint];
	[self removeConstraint:_scrubberRightConstraint];
	_scrubberRightConstraint.constant = -kGMFBarPaddingX;
	[self addConstraint:_scrubberRightConstraint];
}

- (void)hideBackground {
	_backgroundView.hidden = YES;
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  NSAssert(false, @"Invalid initializer.");
  return nil;
}

- (void)dealloc {
	[_scrubber removeTarget:self
				     action:NULL
		   forControlEvents:UIControlEventAllEvents];
	[_playButton removeTarget:self
					 action:NULL
		   forControlEvents:UIControlEventTouchUpInside];
	[_hdButton removeTarget:self
				     action:NULL
		   forControlEvents:UIControlEventTouchUpInside];
	[_minimizeButton removeTarget:self
                      action:NULL
            forControlEvents:UIControlEventTouchUpInside];
}


- (void)setupLayoutConstraints { //Samba SDK Player
  [_backgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_playButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_secondsPlayedLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_totalSecondsLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_scrubber setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_hdButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_minimizeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_timeSeparator setTranslatesAutoresizingMaskIntoConstraints:NO];

  NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_backgroundView,
																 _playButton,
                                                                 _secondsPlayedLabel,
																 _timeSeparator,
																 _totalSecondsLabel,
                                                                 _scrubber,
																 _hdButton,
                                                                 _minimizeButton);
  
  NSArray *constraints = [[NSArray alloc] init];
  
  // Make the background view occupy the full height of the view.
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_backgroundView]|"
                                                         options:NSLayoutFormatAlignAllBaseline
                                                         metrics:nil
                                                           views:viewsDictionary]];
  
  // Make the background view occupy the full width of the view.
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_backgroundView]|"
                                                         options:NSLayoutFormatAlignAllBaseline
                                                         metrics:nil
                                                           views:viewsDictionary]];
	
  // Make the minimize button occupy the full height of the view.
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%.0f-[_minimizeButton]-%.0f-|", _padding.origin.y, _padding.size.height]
                                                         options:NSLayoutFormatAlignAllBaseline
                                                         metrics:nil
                                                           views:viewsDictionary]];
  
  // Position the minimize button kGMFBarPaddingX from the right of the background view.
  constraints = [constraints arrayByAddingObject:
                 [NSLayoutConstraint constraintWithItem:_minimizeButton
                                              attribute:NSLayoutAttributeRight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:_backgroundView
                                              attribute:NSLayoutAttributeRight
                                             multiplier:1.0f
											   constant:-kGMFBarPaddingX]];
	
  // Make the hd button occupy the full height of the view.
  constraints = [constraints arrayByAddingObjectsFromArray:
				   [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%.0f-[_hdButton]-%.0f-|", _padding.origin.y, _padding.size.height]
														   options:NSLayoutFormatAlignAllBaseline
														   metrics:nil
															 views:viewsDictionary]];
	
	// Position the hd button kGMFBarPaddingX from the right of the minimize button.
  constraints = [constraints arrayByAddingObject:
			   [NSLayoutConstraint constraintWithItem:_hdButton
											attribute:NSLayoutAttributeRight
											relatedBy:NSLayoutRelationEqual
											   toItem:_minimizeButton
											attribute:NSLayoutAttributeLeft
										   multiplier:1.0f
											 constant:-kGMFBarPaddingX]];
	
  // Make the scrubber occupy the full height of the view.
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%.0f-[_scrubber]-%.0f-|", _padding.origin.y, _padding.size.height]
                                                         options:NSLayoutFormatAlignAllBaseline
                                                         metrics:nil
                                                           views:viewsDictionary]];
  
  // Position the scrubber kGMFBarPaddingX to the left of the total seconds label.
  constraints = [constraints arrayByAddingObject:
                 _scrubberRightConstraint = [NSLayoutConstraint constraintWithItem:_scrubber
                                              attribute:NSLayoutAttributeRight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:_hdButton
                                              attribute:NSLayoutAttributeLeft
                                             multiplier:1.0f
                                               constant:-kGMFBarPaddingX]];
  
  // Position the scrubber kGMFBarPaddingX to the right of the seconds played label.
  constraints = [constraints arrayByAddingObject:
                 [NSLayoutConstraint constraintWithItem:_scrubber
                                              attribute:NSLayoutAttributeLeft
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:_totalSecondsLabel
                                              attribute:NSLayoutAttributeRight
                                             multiplier:1.0f
                                               constant:kGMFBarPaddingX]];
	
  // Make the total seconds label occupy the full height of the view.
  constraints = [constraints arrayByAddingObjectsFromArray:
				 [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%.0f-[_totalSecondsLabel]-%.0f-|", _padding.origin.y, _padding.size.height]
											 options:NSLayoutFormatAlignAllBaseline
												metrics:nil
												views:viewsDictionary]];
	 
  // Position the total seconds label kGMFBarPaddingX from the left of the scrubber
  constraints = [constraints arrayByAddingObject:
	 [NSLayoutConstraint constraintWithItem:_totalSecondsLabel
										attribute:NSLayoutAttributeLeft
										relatedBy:NSLayoutRelationEqual
									    toItem:_timeSeparator
									    attribute:NSLayoutAttributeRight
									    multiplier:1.0f
									    constant:2.0f]];
	
	
	// Make the time separator label occupy the full height of the view.
	constraints = [constraints arrayByAddingObjectsFromArray:
				   [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%.0f-[_timeSeparator]-%.0f-|", _padding.origin.y, _padding.size.height]
														   options:NSLayoutFormatAlignAllBaseline
														   metrics:nil
															 views:viewsDictionary]];
	
	// Position the time separator label kGMFBarPaddingX from the left of the totalSeconds
	constraints = [constraints arrayByAddingObject:
				   [NSLayoutConstraint constraintWithItem:_timeSeparator
												attribute:NSLayoutAttributeLeft
												relatedBy:NSLayoutRelationEqual
												   toItem:_secondsPlayedLabel
												attribute:NSLayoutAttributeRight
											   multiplier:1.0f
												 constant:2.0f]];
	
	
  // Make the seconds played label occupy the full height of the view
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%.0f-[_secondsPlayedLabel]-%.0f-|", _padding.origin.y, _padding.size.height]
                                                         options:NSLayoutFormatAlignAllBaseline
                                                         metrics:nil
                                                           views:viewsDictionary]];
  
  // Position the seconds played label kGMFBarPaddingX to the right of the background view.
  constraints = [constraints arrayByAddingObject:
                 [NSLayoutConstraint constraintWithItem:_secondsPlayedLabel
                                              attribute:NSLayoutAttributeLeft
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:_playButton
                                              attribute:NSLayoutAttributeRight
                                             multiplier:1.0f
                                               constant:kGMFBarPaddingX]];
	
  // Make the play button occupy the full height of the view.
  constraints = [constraints arrayByAddingObjectsFromArray:
			   [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%.0f-[_playButton]-%.0f-|", _padding.origin.y, _padding.size.height]
													   options:NSLayoutFormatAlignAllBaseline
													   metrics:nil
														 views:viewsDictionary]];

  // Position the play button kGMFBarPaddingX to the right of the background view.
  constraints = [constraints arrayByAddingObject:
				   [NSLayoutConstraint constraintWithItem:_playButton
												attribute:NSLayoutAttributeLeft
												relatedBy:NSLayoutRelationEqual
												   toItem:_backgroundView
												attribute:NSLayoutAttributeLeft
											   multiplier:1.0f
												 constant:kGMFBarPaddingX]];
  [self addConstraints:constraints];
}

- (void)setTotalTime:(NSTimeInterval)totalTime {
  _totalSeconds = totalTime;
}

- (void)setDownloadedTime:(NSTimeInterval)downloadedTime {
  _downloadedSeconds = downloadedTime;
}

- (void)setMediaTime:(NSTimeInterval)mediaTime {
  _mediaTime = mediaTime;
}

- (CGFloat)preferredHeight {
  return [[GMFResources playerBarBackgroundImage] size].height * 1.0;
}

- (void)setDelegate:(id<GMFPlayerControlsViewDelegate>)delegate {
  _delegate = delegate;
}

- (void)updateScrubberAndTime {
  // TODO(tensafefrogs): Handle live streams
  [_scrubber setMaximumValue:_totalSeconds];
  [_totalSecondsLabel setText:[self stringWithDurationSeconds:_totalSeconds]];
  [_secondsPlayedLabel setText:[self stringWithDurationSeconds:_mediaTime]];
  if (_userScrubbing) {
    [self setMediaTime:[_scrubber value]];
    _userScrubbing = NO;
  } else {
    // If time is this low, we might be resetting the slider after a video completes, so don't want
    // it to slide back to zero animated.
    BOOL animated = _mediaTime <= 0.5;
    [_scrubber setValue:_mediaTime animated:animated];
  }
}

- (void)applyControlTintColor:(UIColor *)color { //SDK Samba customization
  [_scrubber setMinimumTrackTintColor:color];
  //[_scrubber setThumbTintColor:color];
  //[_minimizeButton GMF_applyTintColor:color];
}

#pragma mark Private Methods

// Formats media time into a more readable format of HH:MM:SS.
- (NSString *)stringWithDurationSeconds:(NSTimeInterval)durationSeconds {
  NSInteger durationSecondsRounded = lround(durationSeconds);
  NSInteger seconds = (durationSecondsRounded) % 60;
  NSInteger minutes = (durationSecondsRounded / 60) % 60;
  NSInteger hours = durationSecondsRounded / 3600;
  if (hours) {
    return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long) hours, (long) minutes, (long) seconds];
  } else {
    return [NSString stringWithFormat:@"%ld:%02ld", (long) minutes, (long) seconds];
  }
}

- (void)setSeekbarThumbToDefaultImage {
  [_scrubber setThumbImage:
      [GMFResources playerBarScrubberThumbImage] forState:UIControlStateNormal];
}

- (void)didPressPlay:(id)sender {	
  if ([_playButton.currentImage.accessibilityIdentifier isEqualToString:@"play"])
    [_delegate didPressPlay];
  else if ([_playButton.currentImage.accessibilityIdentifier isEqualToString:@"pause"])
	[_delegate didPressPause];
  else if ([_playButton.currentImage.accessibilityIdentifier isEqualToString:@"replay"])
	[_delegate didPressReplay];
}

- (void)didPressPause:(id)sender {
  [_delegate didPressPause];
}

- (void)didPressReplay:(id)sender {
  [_delegate didPressReplay];
}

- (void)didPressMinimize:(id)sender {
  [_delegate didPressMinimize];
}

-(void)didPressHd:(id)sender {
  [_delegate didPressHd];
}

- (void)didScrubbingStart:(id)sender {
  _userScrubbing = YES;
  [_delegate didStartScrubbing];
}

- (void)didScrubbingProgress:(id)sender {
  _userScrubbing = YES;
  [self updateScrubberAndTime];
}

- (void)didScrubbingEnd:(id)sender {
  _userScrubbing = YES;
  [_delegate didSeekToTime:[_scrubber value]];
  [_delegate didEndScrubbing];
  [self updateScrubberAndTime];
}

- (void)setSeekbarTrackColor:(UIColor *)color {
  [_scrubber setMinimumTrackTintColor:color];
}

- (void)disableSeekbarInteraction {
  
  // Hide the seek bar thumb by replacing it with a transparent image.
  // Note: We cannot simply set the image to be a zero-size image (ex. [[UIImage alloc] init])
  // because this will cause the seekbar's height, and therefore its layout, to change.
  UIImage *currentThumbImage = [_scrubber currentThumbImage];
  [_scrubber setThumbImage:[self transparentImageWithSize:currentThumbImage.size]
                  forState:UIControlStateNormal];
  
  [_scrubber setUserInteractionEnabled:NO];
}

// Create a transparent image with the given size.
- (UIImage *)transparentImageWithSize:(CGSize)size {
  CGRect rect = CGRectMake(0, 0, size.width, size.height);
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
  [[UIColor clearColor] setFill];
  UIRectFill(rect);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return image;
}

- (void)enableSeekbarInteraction {
  [self setSeekbarThumbToDefaultImage];
  [_scrubber setUserInteractionEnabled:YES];
}

- (UIButton *)playerButtonWithImage:(UIImage *)image
                             action:(SEL)action
                 accessibilityLabel:(NSString *)accessibilityLabel {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setImage:image forState:UIControlStateNormal];
  [button addTarget:self
             action:action
   forControlEvents:UIControlEventTouchUpInside];
  [button setAccessibilityLabel:accessibilityLabel];
  [button setExclusiveTouch:YES];
  [button setShowsTouchWhenHighlighted:YES];
  [button sizeToFit];
  return button;
}

@end

