//
//  DownloadData.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 29/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

public struct DownloadData {
    var mediaId: String
    var mediaTitle: String
    var totalDownloadSizeInMB: Double
    var sambaMedia: SambaMediaConfig
    var sambaSubtitle: SambaSubtitle
}


public struct DownloadState {
    var downloadPercentage: Float
    var downloadData: DownloadData
    var state: State
    
    public enum State {
        case WAITING
        case COMPLETED
        case CANCELED
        case IN_PROGRESS
        case FAILED
        case DELETED
    }
    
}
