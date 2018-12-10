//
//  StartDownloadHelper.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 30/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation


class StartDownloadHelper {
    
    private init() {}
    
    static func prepare(request: SambaDownloadRequest, successCallback: @escaping (SambaDownloadRequest) -> Void, errorCallback: @escaping (Error?,String) -> Void) {
        
        getSambaTracksFrom(request: request, onSuccess: { (sambatracks) in
            request.sambaVideoTracks = sambatracks.filter{!$0.isProgressive}
            request.sambaAudioTracks = sambatracks.filter{$0.isProgressive}
            
            if let media = request.sambaMedia as? SambaMediaConfig, let captions = media.captions, !captions.isEmpty {
                request.sambaSubtitles = captions.filter{!$0.url.isEmpty}.map({ (caption) -> SambaSubtitle in
                    return SambaSubtitle(title: caption.label, mediaID: media.id, caption: caption)
                })
            }
            
            successCallback(request)
        },
        onError: { (error) in
            errorCallback(nil, error)
        })
        
    }
    
    
    static func getSambaTracksFrom(request: SambaDownloadRequest, onSuccess: @escaping (_ sambaTracks: [SambaTrack]) -> Void , onError: @escaping (_ error: String) -> Void) {
        
        DispatchQueue.global(qos: .background).async {
            let media = request.sambaMedia as! SambaMediaConfig
            let urlString = OfflineUtils.getSambaMediaUrl(media: media)
            if let finalUrl = urlString, let url = URL(string: finalUrl) {
                
                let tracks: [SambaTrack]!
                var errorMsg: String?
                if url.pathExtension.contains("m3u8") {
                   
                    do {
                        let outputs = try OfflineUtils.extractM3u8(url: url)
                        
                        tracks = outputs.map({ (item) in
                            let sizeInMb =  OfflineUtils.getSizeInMB(bitrate: item.bandwidth, duration: CLong(media.duration))
                            let sambaTrack = SambaTrack(title: item.label, sizeInMb: sizeInMb, width: item.width, height: item.height, isProgressive: false, output: item)
                            
                            return sambaTrack
                        })
                    } catch {
                        errorMsg = "Error to prepare the download"
                    }
                    
                    
                } else {
                    do {
                        let output = SambaPlayer.Output(url: url, label: media.title, width: 0, height: 0, bandwidth: media.bitrate ?? 0)
                        
                    
                        let sizeInMb =  OfflineUtils.getSizeInMB(bitrate: output.bandwidth, duration: CLong(media.duration))
                        let sambaTrack = SambaTrack(title: output.label, sizeInMb: sizeInMb, width: output.width, height: output.height, isProgressive: true, output: output)
                    
                        tracks = [sambaTrack]
                    } catch {
                        errorMsg = "Error to prepare the download"
                    }
                }
                
                

                DispatchQueue.main.async {
                    
                    guard errorMsg == nil else {
                        onError(errorMsg!)
                        return
                    }
                    
                    onSuccess(tracks)
                }
                
                
            }
        }
        
    }
    
}
