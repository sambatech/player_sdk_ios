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

#import "GMFResources.h"
#import "GMFVideoPlayer.h"

@implementation GMFResources

+ (UIImage *)playerBarPlayButtonImage {
  UIImage* image = [self imageNamed:@"player_control_play"];
  image.accessibilityIdentifier = @"play";
  return image;
}

+ (UIImage *)playerBarPlayLargeButtonImage {
  UIImage* image = [self imageNamed:@"player_control_play_large"];
  image.accessibilityIdentifier = @"play";
  return image;
}

+ (UIImage *)playerBarPauseButtonImage {
  UIImage* image = [self imageNamed:@"player_control_pause"];
  image.accessibilityIdentifier = @"pause";
  return image;
}

+ (UIImage *)playerBarPauseLargeButtonImage {
  UIImage* image = [self imageNamed:@"player_control_pause_large"];
  image.accessibilityIdentifier = @"pause";
  return image;
}

+ (UIImage *)playerBarReplayButtonImage {
  UIImage* image = [self imageNamed:@"player_control_replay"];
  image.accessibilityIdentifier = @"replay";
  return image;
}

+ (UIImage *)playerBarReplayLargeButtonImage {
  return [self imageNamed:@"player_control_replay_large"];  
}

+ (UIImage *)playerBarMaximizeButtonImage {
  return [self imageNamed:@"player_control_maximize"];
}

+ (UIImage *)playerBarMinimizeButtonImage {
  return [self imageNamed:@"player_control_minimize"];
}

+ (UIImage *)playerBarHdButtonImage {
  return [self imageNamed:@"player_control_hd"];
}

+ (UIImage *)playerBarScrubberThumbImage {
  return [self imageNamed:@"player_scrubber_thumb"];
}

+ (UIImage *)playerTitleLiveIcon {
	return [self imageNamed:@"player_control_ic_live"];
}

+ (UIImage *)playerBarBackgroundImage {
  return [self imageNamed:@"player_controls_background"];
}

+ (UIImage *)playerTitleBarBackgroundImage {
  return [self imageNamed:@"player_controls_title_bar_background"];
}

#pragma mark Private Methods

+ (UIImage *)imageNamed:(NSString *)name
            stretchable:(BOOL)stretchable {
  UIImage *image = [UIImage imageNamed:name inBundle:[NSBundle bundleForClass:GMFResources.self] compatibleWithTraitCollection:nil];

  NSAssert(image, @"There is no image called %@", name);
  if (stretchable) {
    // Stretching the image by using a center cap.
    CGSize size = [image size];
    return [image stretchableImageWithLeftCapWidth:size.width / 2.0
                                      topCapHeight:size.height / 2.0];
  } else {
    return image;
  }
}

+ (UIImage *)imageNamed:(NSString *)name {
  return [self imageNamed:name stretchable:NO];
}

@end

