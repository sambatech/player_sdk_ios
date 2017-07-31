//
//  GMFIMASettings.h
//  SambaPlayer
//
//  Created by Leandro Zanol on 7/21/17.
//  Copyright © 2017 Samba Tech. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleInteractiveMediaAds;

@interface GMFAdsSettings : IMAAdsRenderingSettings

@property(nonatomic) NSUInteger maxRedirects;
@property(nonatomic) BOOL debugMode;
@property(nonatomic) float vastLoadTimeout;

@end
