//
//  GMFIMASettings.m
//  SambaPlayer
//
//  Created by Leandro Zanol on 7/24/17.
//  Copyright © 2017 Samba Tech. All rights reserved.
//

#import "AdsSettings.h"
@import GoogleInteractiveMediaAds;

@implementation AdsSettings

- (instancetype)init {
	if (self = [super init]) {
		self.maxRedirects = 4;
		self.rendering = [[IMAAdsRenderingSettings alloc] init];
	}
	
	return self;
}

@end
