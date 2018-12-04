//
//  OfflineUtils.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 29/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

public class OfflineUtils {
    
    private static let MEDIAS_KEY_DOWNLOADED = "MEDIAS_KEY_DOWNLOADED"
    private static let MEDIAS_KEY_DOWNLOADING = "MEDIAS_KEY_DOWNLOADING"
    private static let MEDIAS_LOCATION_KEY = "MEDIAS_LOCATION_KEY"
    
    private init(){}
    
    private static func persistMedias(_ medias: [SambaMediaConfig], key: String) {
        
        let mediaOffline = medias.map{SambaOfflineMedia.from(sambaMedia: $0)}
        
        let jsonData = try? JSONEncoder().encode(mediaOffline)
        
        guard let data = jsonData else {return}
        
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private static func getPersistedMedias(key: String) -> [SambaMediaConfig]? {
        let jsonData = UserDefaults.standard.data(forKey: key)
        
        guard let data = jsonData else {
            return nil
        }
    
        let mediasOffline = try? JSONDecoder().decode([SambaOfflineMedia].self, from: data)
        
        guard let medias = mediasOffline else {
            return nil
        }
        
        return medias.map{$0.toSambaMedia()}
    }
    
    static func persistDownloadedMedias(_ medias: [SambaMediaConfig]) {
        persistMedias(medias, key: MEDIAS_KEY_DOWNLOADED)
    }
    
    static func persistDownloadingMedias(_ medias: [SambaMediaConfig]) {
        persistMedias(medias, key: MEDIAS_KEY_DOWNLOADING)
    }
    
    static func getPersistDownloadedMedias() -> [SambaMediaConfig]? {
        return getPersistedMedias(key: MEDIAS_KEY_DOWNLOADED)
    }
    
    static func getPersistDownloadingMedias() -> [SambaMediaConfig]? {
        return getPersistedMedias(key: MEDIAS_KEY_DOWNLOADING)
    }
    
    
    static func getSambaMediaUrl(media: SambaMediaConfig) -> String? {
        var urlOpt = media.url
        
        // outputs
        if let outputs = media.outputs, outputs.count > 0 {
            // assume first output in case of no default
            urlOpt = outputs[0].url
            
            for (_, v) in outputs.enumerated() where v.isDefault {
                urlOpt = v.url
            }
        }

        guard let urlString = urlOpt else { return nil }
        
        return urlString
    }
    
    static func extractM3u8(url: URL?) -> [SambaPlayer.Output]  {
        guard let url = url,
            url.pathExtension.contains("m3u8"),
            let text = try? String(contentsOf: url, encoding: .utf8)
            else { return [SambaPlayer.Output]() }
        
        let baseUrl = url.absoluteString.replacingOccurrences(of: "[\\w\\.]+\\?.+", with: "", options: .regularExpression)
        var outputs = Set<SambaPlayer.Output>()
        var label: String?
        var width: Int = 0
        var height: Int = 0
        var bandwidth: CLong = 0
        
        for line in Helpers.matchesForRegexInText("[^\\r\\n]+", text: text) {
            if line.hasPrefix("#EXT-X-STREAM-INF") {
                if let range = line.range(of: "RESOLUTION\\=[^\\,\\r\\n]+", options: .regularExpression)  {
                    
                    let kv = line.substring(with: range)
                    
                    if let rangeKv = kv.range(of: "\\d+$", options: .regularExpression),
                        let n = Int(kv.substring(with: rangeKv)) {
                        
                        label = "\(kv.contains("x") ? "\(n)p" : "\(n/1000)k")"
                    }
                    
                    if kv.contains("x") {
                        
                        let s1ArrRes = kv.components(separatedBy: "=")
                        
                        if s1ArrRes.count > 1 {
                            let finalResArr = s1ArrRes[1].components(separatedBy: "x")
                            
                            if finalResArr.count > 1 {
                                height = Int(finalResArr[0]) ?? 0
                                width = Int(finalResArr[1]) ?? 0
                            }
                        }
                       
                    } else {
                        let s2ArrRes = kv.components(separatedBy: "=")
                        if s2ArrRes.count > 1 {
                            bandwidth = CLong(s2ArrRes[1]) ?? 0
                        }
                    }
                    
                }
                
                if  let range = line.range(of: "BANDWIDTH\\=\\d+", options: .regularExpression) {
                    let kv = line.substring(with: range)
                    let s2ArrRes = kv.components(separatedBy: "=")
                    if s2ArrRes.count > 1 {
                        bandwidth = CLong(s2ArrRes[1]) ?? 0
                    }
            
                }
                
            } else if let labelString = label,
                line.hasSuffix(".m3u8"),
                let url = URL(string: line.hasPrefix("http") ? line : baseUrl + line) {

                outputs.insert(SambaPlayer.Output(url: url, label: labelString, width: width, height: height,bandwidth: bandwidth))
                label = nil
            }
        }
        
        return outputs.sorted(by: { $0.hashValue < $1.hashValue })
    }
    
    static func getSizeInMB(bitrate: CLong, duration: CLong) -> Double {
        
        let bitrateInSeconds = (Double(bitrate) / 1000000.0) as Double
        
        return (bitrateInSeconds * Double(duration)) / Double(8)
    }
    
    static func isValidRequest(_ request: SambaDownloadRequest) -> Bool {
          return request.sambaMedia != nil && request.sambaTrackForDownload != nil
    }
    
    static func saveMediaLocation(with media: SambaMediaConfig, location: Data) {
        UserDefaults.standard.set(location, forKey: "\(media.id)_\(MEDIAS_LOCATION_KEY)")
    }
    
    static func getMediaLocation(from media: SambaMediaConfig) -> Data? {
        return UserDefaults.standard.data(forKey: "\(media.id)_\(MEDIAS_LOCATION_KEY)")
    }
    
    static func removeMediaLocation(from media: SambaMediaConfig) {
        UserDefaults.standard.removeObject(forKey: "\(media.id)_\(MEDIAS_LOCATION_KEY)")
    }
    
    static func localAssetForMedia(withMedia media: SambaMediaConfig) -> AVURLAsset? {
        guard let localFileLocation = getMediaLocation(from: media) as? Data else { return nil }
        
        var bookmarkDataIsStale = false
        do {
            guard let url = try URL(resolvingBookmarkData: localFileLocation,
                                    bookmarkDataIsStale: &bookmarkDataIsStale) else {
                                        fatalError("Failed to create URL from bookmark!")
            }
            
            if bookmarkDataIsStale {
                fatalError("Bookmark data is stale!")
            }
            
            return AVURLAsset(url: url)
        } catch {
            fatalError("Failed to create URL from bookmark with error: \(error)")
        }
    }
    
    static func sendNotification(with downloadState: DownloadState) {
        NotificationCenter.default.post(name: .SambaDownloadStateChanged, object: downloadState, userInfo: nil)
    }
    
}
