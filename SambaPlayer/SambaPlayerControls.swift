//
//  SambaPlayerControls.swift
//  SambaPlayer
//
//  Created by Luiz Henrique Bueno Byrro on 27/10/17.
//  Copyright © 2017 Samba Tech. All rights reserved.
//

import Foundation

@objc public enum SambaPlayerControls: Int, RawRepresentable  {
    case play, playLarge, fullscreen, seekbar, topBar, bottomBar, time, menu, liveIcon
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
        case .play:
            return "play"
        case .playLarge:
            return "playLarge"
        case .fullscreen:
            return "fullscreen"
        case .seekbar:
            return "seekbar"
        case .topBar:
            return "topBar"
        case .bottomBar:
            return "bottomBar"
        case .time:
            return "time"
        case .menu:
            return "menu"
        case .liveIcon:
            return "liveIcon"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "play":
            self = .play
        case "playLarge":
            self = .playLarge
        case "fullscreen":
            self = .fullscreen
        case "seekbar":
            self = .seekbar
        case "topBar":
            self = .topBar
        case "bottomBar":
            self = .bottomBar
        case "time":
            self = .time
        case "menu":
            self = .menu
        case "liveIcon":
            self = .liveIcon
        default:
            self = .topBar
        
        }
    }
}
