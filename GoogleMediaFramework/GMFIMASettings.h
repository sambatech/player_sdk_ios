//
//  GMFIMASettings.h
//  SambaPlayer
//
//  Created by Leandro Zanol on 7/21/17.
//  Copyright © 2017 Samba Tech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GMFIMASettings

@property(nonatomic) NSUInteger maxRedirects;
@property(nonatomic) BOOL enableDebugMode;
@property(nonatomic, strong) IMAAdsRenderingSettings *rendering;

@end
