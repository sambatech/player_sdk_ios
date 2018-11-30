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
        
        getSambaTracksFromM3U8(request: request) { (sambatracks) in
            
        }
        
        
    }
    
    
    static func getSambaTracksFromM3U8(request: SambaDownloadRequest, onSuccess: @escaping (_ sambaTracks: [SambaTrack]) -> Void) {
        
        DispatchQueue.global().async {
            let media = request.sambaMedia as! SambaMediaConfig
            let urlString = OfflineUtils.getSambaMediaUrl(media: media)
            if let finalUrl = urlString, let url = URL(string: finalUrl) {
               let outputs = OfflineUtils.extractM3u8(url: url)
            }
        }
        
    }
    
}
