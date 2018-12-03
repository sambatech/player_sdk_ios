//
//  DownloadData.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 29/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

public struct DownloadData: Codable {
    var mediaId: String
    var mediaTitle: String
    var totalDownloadSizeInMB: Double
    var sambaMedia: SambaMediaConfig?
    var sambaSubtitle: SambaSubtitle?
    
    private enum CodingKeys: String, CodingKey {
        case mediaId
        case mediaTitle
        case totalDownloadSizeInMB
    }
    
    init(mediaId: String, mediaTitle: String, totalDownloadSizeInMB: Double, sambaMedia: SambaMediaConfig, sambaSubtitle: SambaSubtitle?) {
        self.mediaId = mediaId
        self.mediaTitle = mediaTitle
        self.totalDownloadSizeInMB = totalDownloadSizeInMB
        self.sambaMedia = sambaMedia
        self.sambaSubtitle = sambaSubtitle
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        mediaId = try container.decode(String.self, forKey: .mediaId)
        mediaTitle = try container.decode(String.self, forKey: .mediaTitle)
        totalDownloadSizeInMB = try container.decode(Double.self, forKey: .totalDownloadSizeInMB)
        sambaMedia = nil
        sambaSubtitle = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(mediaId, forKey: .mediaId)
        try container.encode(mediaTitle, forKey: .mediaTitle)
        try container.encode(totalDownloadSizeInMB, forKey: .totalDownloadSizeInMB)
    }
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
        case progress
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