//
//  Tracking.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 31/08/2018.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

func getTracking(by isLive: Bool) -> Tracking {
    if (isLive) {
        return TrackingLive()
    } else {
        return TrackingVOD()
    }
}

protocol Tracking: Plugin {
    
}
