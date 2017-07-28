//
//  GMFIMASettings.m
//  SambaPlayer
//
//  Created by Leandro Zanol on 7/24/17.
//  Copyright © 2017 Samba Tech. All rights reserved.
//

#import "GMFAdsSettings.h"
@import GoogleInteractiveMediaAds;

@implementation GMFAdsSettings

- (instancetype)init {
	if (self = [super init]) {
		self.maxRedirects = 4;
	}
	
	return self;
}

@end
