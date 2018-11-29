//
//  DownloadRequest.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 29/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation


public struct SambaDownloadRequest {
    
    var mediaId: String
    var projectHash: String
    var drmToken: String?
    var totalDownloadSize: Double?
    
    
    var sambaMedia: SambaMedia?
    
    var sambaVideoTracks: [SambaTrack]?
    var sambaAudioTracks: [SambaTrack]?
    var sambaSubtitles: [SambaSubtitle]?
    
    
    var sambaTrackForDownload: SambaTrack?
    var sambaSubtitlesForDownload: SambaSubtitle?
    
    
}
