//
//  SambaDownloadTracker.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 30/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation
import AVFoundation

class SambaDownloadTracker: NSObject {
    // MARK: Properties
    
    private static let DOWNLOAD_ID = "SAMBA_PLAYER_DOWNLOAD_ID"
    
    static let sharedInstance = SambaDownloadTracker()
    
    /// Internal Bool used to track if the AssetPersistenceManager finished restoring its state.
    private var didRestorePersistenceManager = false
    
    /// The AVAssetDownloadURLSession to use for managing AVAssetDownloadTasks.
    fileprivate var assetDownloadURLSession: AVAssetDownloadURLSession!
    
    /// Internal map of AVAssetDownloadTask to its corresponding Asset.
    fileprivate var activeDownloadsMap = [AVAssetDownloadTask: SambaMediaConfig]()
    
    /// Internal map of AVAssetDownloadTask to its resoled AVMediaSelection
    fileprivate var mediaSelectionMap = [AVAssetDownloadTask: AVMediaSelection]()
    
    // MARK: Intialization
    
    override private init() {
        
        super.init()
        
        //        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: SambaDownloadTracker.DOWNLOAD_ID)
        //
        //
        //        assetDownloadURLSession = AVAssetDownloadURLSession(configuration: backgroundConfiguration,
        //                                      assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
        
        //        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
    }
    
    
    //    @objc func applicationWillResignActive() {
    //        activeDownloadsMap.forEach { (arg0) in
    //
    //            let (key, value) = arg0
    //
    //            key.suspend()
    //            key.resume()
    //
    //        }
    //    }
    
    func prepareDownload(with request: SambaDownloadRequest, successCallback: @escaping (SambaDownloadRequest) -> Void, errorCallback: @escaping (Error?,String) -> Void) {
        
        SambaApi().requestMedia(SambaMediaRequest(projectHash: request.projectHash, mediaId: request.mediaId), onComplete: { [weak self] (sambaMedia) in
            
            guard let strongSelf = self else {return}
            
            let sambaMediaConfig = sambaMedia as! SambaMediaConfig
            
            if strongSelf.isDownloading(sambaMediaConfig.id) {
                errorCallback(nil, "Media is downloading")
            } else if strongSelf.isDownloaded(sambaMediaConfig.id) {
                errorCallback(nil, "Media already downloaded")
            } else {
                request.sambaMedia = sambaMediaConfig
                
                if let drmRequest = sambaMediaConfig.drmRequest {
                    successCallback(request)
                } else {
                    StartDownloadHelper.prepare(request: request, successCallback: successCallback, errorCallback: errorCallback)
                }
                
            }
            
        }) { (error, response) in
            errorCallback(error, "Error to resquest Media")
        }
        
    }
    
    func performDownload(with request: SambaDownloadRequest) {
        
        let media = request.sambaMedia as! SambaMediaConfig
        
        if isDownloading(media.id) {
            
        } else if isDownloaded(media.id) {
            
        }  else {
            if OfflineUtils.isValidRequest(request) {
                startDownload(request)
            }
        }
    }
    
    
    private func startDownload(_ request: SambaDownloadRequest) {
        
    }
    
    func isDownloading(_ mediaId: String) -> Bool {
        return false
    }
    
    func isDownloaded(_ mediaId: String) -> Bool {
        return false
    }
    
}


extension Notification.Name {
    /// Notification for when download progress has changed.
    static let AssetDownloadProgress = Notification.Name(rawValue: "AssetDownloadProgressNotification")
    
    /// Notification for when the download state of an Asset has changed.
    static let AssetDownloadStateChanged = Notification.Name(rawValue: "AssetDownloadStateChangedNotification")
    
    /// Notification for when AssetPersistenceManager has completely restored its state.
    static let AssetPersistenceManagerDidRestoreState =
        Notification.Name(rawValue: "AssetPersistenceManagerDidRestoreStateNotification")
}

