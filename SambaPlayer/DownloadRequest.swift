//
//  DownloadRequest.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 29/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation


public class SambaDownloadRequest: NSObject {
    
    public var mediaId: String
    public var projectHash: String
    public var drmToken: String?
    public var totalDownloadSize: Double?
    
    
    public var sambaMedia: SambaMedia?
    
    public var sambaVideoTracks: [SambaTrack]?
    public var sambaAudioTracks: [SambaTrack]?
    public var sambaSubtitles: [SambaSubtitle]?
    
    
    public var sambaTrackForDownload: SambaTrack?
    public var sambaSubtitleForDownload: SambaSubtitle?
    
    public init(mediaId: String, projectHash: String) {
        self.mediaId = mediaId
        self.projectHash = projectHash
    }
}
