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
    var sambaSubtitle: SambaSubtitle?
}


public struct DownloadState {
    var downloadPercentage: Float
    var downloadData: DownloadData
    var state: State
    
    public enum State: String {
        case WAITING
        case COMPLETED
        case CANCELED
        case IN_PROGRESS
        case FAILED
        case DELETED
    }
    
    public enum Key: String {
        case state
    }
    
    static func from(state: DownloadState.State,
                                         totalDownloadSize: Double,
                                         downloadPercentage: Float,
                                         media: SambaMediaConfig,
                                         sambaSubtitle: SambaSubtitle? = nil) -> DownloadState {
        
        let downloadData = DownloadData(mediaId: media.id,
                                        mediaTitle: media.title,
                                        totalDownloadSizeInMB: totalDownloadSize,
                                        sambaMedia: media,
                                        sambaSubtitle: sambaSubtitle)
        
        return DownloadState(downloadPercentage: downloadPercentage, downloadData: downloadData, state: state)
    }
    
}
