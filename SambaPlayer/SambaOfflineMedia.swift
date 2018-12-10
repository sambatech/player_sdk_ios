//
//  SambaOfflineMedia.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 29/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

class SambaOfflineMedia: NSObject, Codable {
    
    public var title = ""
    public var url: String?
    public var backupUrls = [String]()
    public var adUrl: String?
    public var outputs: [SambaMediaOutput]?
    public var captions: [SambaMediaCaption]?
    public var captionsConfig = SambaMediaCaptionsConfig()
    public var deliveryType = "other"
    public var thumbURL: String?
    public var externalThumbURL: String?
    public var isLive = false
    public var isAudio = false
    public var isOffline = false
    public var isCaptionsOffline = false
    public var isDvr = false
    public var theme: UInt = 0x72BE44
    public var themeColorHex: String = "#72BE44"
    public var duration: Float = 0
    
    public var id = ""
    public var projectHash = ""
    public var clientId = 0
    public var projectId = 0
    public var categoryId = 0
    public var sessionId = ""
    public var sttmUrl = "http://sttm.sambatech.com.br/collector/__sttm.gif"
    public var sttmKey = "ae810ebc7f0654c4fadc50935adcf5ec"
    public var drmRequest: DrmRequest?
    public var blockIfRooted = false
    public var retriesTotal = 3
    public var bitrate: CLong?
    public var offlineUrl: String?
    public var offlinePath: String?
    public var downloadData: DownloadData?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case url
        case backupUrls
        case adUrl
        case outputs
        case captions
        case captionsConfig
        case deliveryType
        case thumbURL
        case externalThumbURL
        case isLive
        case isAudio
        case isOffline
        case isCaptionsOffline
        case isDvr
        case theme
        case themeColorHex
        case duration
        
        case id
        case projectHash
        case clientId
        case projectId
        case categoryId
        case sessionId
        case sttmUrl
        case sttmKey
        case drmRequest
        case blockIfRooted
        case retriesTotal
        case bitrate
        case offlineUrl
        case offlinePath
        case downloadData
    }
    
    override init() {}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decode(String.self, forKey: .title)
        url = try? container.decode(String.self, forKey: .url)
        backupUrls = try container.decode([String].self, forKey: .backupUrls)
        adUrl = try? container.decode(String.self, forKey: .adUrl)
        outputs = try? container.decode([SambaMediaOutput].self, forKey: .outputs)
        captions = try? container.decode([SambaMediaCaption].self, forKey: .captions)
        captionsConfig = try container.decode(SambaMediaCaptionsConfig.self, forKey: .captionsConfig)
        deliveryType = try container.decode(String.self, forKey: .deliveryType)
        thumbURL = try? container.decode(String.self, forKey: .thumbURL)
        externalThumbURL = try? container.decode(String.self, forKey: .externalThumbURL)
        isLive = try container.decode(Bool.self, forKey: .isLive)
        isAudio = try container.decode(Bool.self, forKey: .isAudio)
        isOffline = try container.decode(Bool.self, forKey: .isOffline)
        isCaptionsOffline = try container.decode(Bool.self, forKey: .isCaptionsOffline)
        isDvr = try container.decode(Bool.self, forKey: .isDvr)
        theme = try container.decode(UInt.self, forKey: .theme)
        themeColorHex = try container.decode(String.self, forKey: .themeColorHex)
        duration = try container.decode(Float.self, forKey: .duration)
       
        id = try container.decode(String.self, forKey: .id)
        projectHash = try container.decode(String.self, forKey: .projectHash)
        clientId = try container.decode(Int.self, forKey: .clientId)
        projectId = try container.decode(Int.self, forKey: .projectId)
        categoryId = try container.decode(Int.self, forKey: .categoryId)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        sttmUrl = try container.decode(String.self, forKey: .sttmUrl)
        sttmKey = try container.decode(String.self, forKey: .sttmKey)
        drmRequest = try? container.decode(DrmRequest.self, forKey: .drmRequest)
        blockIfRooted = try container.decode(Bool.self, forKey: .blockIfRooted)
        retriesTotal = try container.decode(Int.self, forKey: .retriesTotal)
        bitrate = try? container.decode(CLong.self, forKey: .bitrate)
        offlineUrl = try? container.decode(String.self, forKey: .offlineUrl)
        offlinePath = try? container.decode(String.self, forKey: .offlinePath)
        downloadData = try? container.decode(DownloadData.self, forKey: .downloadData)
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        try container.encode(url, forKey: .url)
        try container.encode(backupUrls, forKey: .backupUrls)
        try container.encode(adUrl, forKey: .adUrl)
        try container.encode(outputs, forKey: .outputs)
        try container.encode(captions, forKey: .captions)
        try container.encode(captionsConfig, forKey: .captionsConfig)
        try container.encode(deliveryType, forKey: .deliveryType)
        try container.encode(thumbURL, forKey: .thumbURL)
        try container.encode(externalThumbURL, forKey: .externalThumbURL)
        try container.encode(isLive, forKey: .isLive)
        try container.encode(isAudio, forKey: .isAudio)
        try container.encode(isOffline, forKey: .isOffline)
        try container.encode(isCaptionsOffline, forKey: .isCaptionsOffline)
        try container.encode(isDvr, forKey: .isDvr)
        try container.encode(theme, forKey: .theme)
        try container.encode(themeColorHex, forKey: .themeColorHex)
        try container.encode(duration, forKey: .duration)

        try container.encode(id, forKey: .id)
        try container.encode(projectHash, forKey: .projectHash)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(sttmUrl, forKey: .sttmUrl)
        try container.encode(sttmKey, forKey: .sttmKey)
        try container.encode(drmRequest, forKey: .drmRequest)
        try container.encode(blockIfRooted, forKey: .blockIfRooted)
        try container.encode(retriesTotal, forKey: .retriesTotal)
        try container.encode(bitrate, forKey: .bitrate)
        try container.encode(offlineUrl, forKey: .offlineUrl)
        try container.encode(offlinePath, forKey: .offlinePath)
        try container.encode(downloadData, forKey: .downloadData)
        
    }
    
    static func from(sambaMedia media: SambaMediaConfig) -> SambaOfflineMedia {
        
        let sambaOfflineMedia = SambaOfflineMedia()
        
        
        sambaOfflineMedia.title = media.title
        sambaOfflineMedia.url = media.url
        sambaOfflineMedia.backupUrls = media.backupUrls
        sambaOfflineMedia.adUrl = media.adUrl
        sambaOfflineMedia.outputs = media.outputs
        sambaOfflineMedia.captions = media.captions
        sambaOfflineMedia.captionsConfig = media.captionsConfig
        sambaOfflineMedia.deliveryType = media.deliveryType
        sambaOfflineMedia.thumbURL = media.thumbURL
        sambaOfflineMedia.externalThumbURL = media.externalThumbURL
        sambaOfflineMedia.isLive = media.isLive
        sambaOfflineMedia.isAudio = media.isAudio
        sambaOfflineMedia.isOffline = media.isOffline
        sambaOfflineMedia.isCaptionsOffline = media.isCaptionsOffline
        sambaOfflineMedia.isDvr = media.isDvr
        sambaOfflineMedia.theme = media.theme
        sambaOfflineMedia.themeColorHex = media.themeColorHex
        sambaOfflineMedia.duration = media.duration

        sambaOfflineMedia.id = media.id
        sambaOfflineMedia.projectHash = media.projectHash
        sambaOfflineMedia.clientId = media.clientId
        sambaOfflineMedia.projectId = media.projectId
        sambaOfflineMedia.categoryId = media.categoryId
        sambaOfflineMedia.sessionId = media.sessionId
        sambaOfflineMedia.sttmUrl = media.sttmUrl
        sambaOfflineMedia.sttmKey = media.sttmKey
        sambaOfflineMedia.drmRequest = media.drmRequest
        sambaOfflineMedia.blockIfRooted = media.blockIfRooted
        sambaOfflineMedia.retriesTotal = media.retriesTotal
        sambaOfflineMedia.bitrate = media.bitrate
        sambaOfflineMedia.offlineUrl = media.offlineUrl
        sambaOfflineMedia.offlinePath = media.offlinePath
        sambaOfflineMedia.downloadData = media.downloadData
        
        return sambaOfflineMedia
    }
    
    
    func toSambaMedia() -> SambaMediaConfig {
        let media = SambaMediaConfig()
        
        media.title = title
        media.url = url
        media.backupUrls = backupUrls
        media.adUrl = adUrl
        media.outputs = outputs
        media.captions = captions
        media.captionsConfig = captionsConfig
        media.deliveryType = deliveryType
        media.thumbURL = thumbURL
        media.externalThumbURL = externalThumbURL
        media.isLive = isLive
        media.isAudio = isAudio
        media.isOffline = isOffline
        media.isCaptionsOffline = isCaptionsOffline
        media.isDvr = isDvr
        media.theme = theme
        media.themeColorHex = themeColorHex
        media.duration = duration
        
        media.id = id
        media.projectHash = projectHash
        media.clientId = clientId
        media.projectId = projectId
        media.categoryId = categoryId
        media.sessionId = sessionId
        media.sttmUrl = sttmUrl
        media.sttmKey = sttmKey
        media.drmRequest = drmRequest
        media.blockIfRooted = blockIfRooted
        media.retriesTotal = retriesTotal
        media.bitrate = bitrate
        media.offlineUrl = offlineUrl
        media.offlinePath = offlinePath
        media.downloadData = downloadData
        
        return media
    }
    
    func toJson() -> String? {
        let encodedData = try? JSONEncoder().encode(self)
        
        guard let data = encodedData else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    static func fromJson(_ json: String) -> SambaOfflineMedia? {
        
        guard let data = json.data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(SambaOfflineMedia.self, from: data)
    }
    
}

