//
//  DownloadData.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 29/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

public class DownloadData: NSObject, Codable {
    public var mediaId: String
    public var mediaTitle: String
    public var totalDownloadSizeInMB: Double
    public var sambaMedia: SambaMediaConfig?
    public var sambaSubtitle: SambaSubtitle?
    
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
    
    required public init(from decoder: Decoder) throws {
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


public class DownloadState: NSObject {
    public var downloadPercentage: Float
    public var downloadData: DownloadData
    public var state: State
    
    public enum State: String {
        case WAITING
        case COMPLETED
        case CANCELED
        case IN_PROGRESS
        case FAILED
        case DELETED
        case PAUSED
        case RESUMED
    }
    
    init(downloadPercentage: Float, downloadData: DownloadData, state: State) {
        self.downloadPercentage = downloadPercentage
        self.downloadData = downloadData
        self.state = state
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
    
    public static func from(notification: Notification) -> DownloadState? {
        guard let downloadState = notification.object as? DownloadState else {
            return nil
        }
        
        return downloadState
    }
    
}
