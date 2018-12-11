//
//  SambaDownloadManager.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 30/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

public class SambaDownloadManager{
    
    public static var sharedInstance = SambaDownloadManager()
    
    
    private init() {
        
        
        
    }
    
    public func config() {
        SambaDownloadTracker.sharedInstance.restoreTasks()
    }
    
    public func prepareDownload(with request: SambaDownloadRequest, successCallback: @escaping (_ request: SambaDownloadRequest) -> Void, errorCallback: @escaping (_ error: Error?, _ msg: String) -> Void) {
        SambaDownloadTracker.sharedInstance.prepareDownload(with: request, successCallback: successCallback, errorCallback: errorCallback)
    }
    
    public func performDownload(with request: SambaDownloadRequest) {
        SambaDownloadTracker.sharedInstance.performDownload(with: request)
    }
    
    public func isDownloading(_ mediaID: String) -> Bool {
        return SambaDownloadTracker.sharedInstance.isDownloading(mediaID)
    }
    
    public func isDownloaded(_ mediaID: String) -> Bool {
        return SambaDownloadTracker.sharedInstance.isDownloaded(mediaID)
    }
    
    public func isPaused(_ mediaId: String) -> Bool {
        return SambaDownloadTracker.sharedInstance.isPaused(mediaId)
    }
    
    public func cancelDownload(for mediaId: String) {
        SambaDownloadTracker.sharedInstance.cancelDownload(for: mediaId)
    }
    
    public func deleteMedia(for mediaId: String) {
        SambaDownloadTracker.sharedInstance.deleteMedia(for: mediaId)
    }
    
    public func deleteAllMedias() {
        SambaDownloadTracker.sharedInstance.deleteAllMedias()
    }
    
    public func cancelAllDownloads() {
        SambaDownloadTracker.sharedInstance.cancelAllDownloads()
    }
    
    public func pauseDownload(for mediaId: String) {
        SambaDownloadTracker.sharedInstance.pauseDownload(for: mediaId)
    }
    
    public func resumeDownload(for mediaId: String) {
        SambaDownloadTracker.sharedInstance.resumeDownload(for: mediaId)
    }
    
    public func pauseAllDownloads()  {
        SambaDownloadTracker.sharedInstance.pauseAllDownloads()
    }
    
    public func resumeAllDownloads()  {
        SambaDownloadTracker.sharedInstance.resumeAllDownloads()
    }
    
    public func getDownloadedMedia(for mediaId: String) -> SambaMedia? {
        return SambaDownloadTracker.sharedInstance.getDownloadedMedia(for: mediaId)
    }
    
    public func getAllDownloadedMedia() -> [SambaMedia] {
        return SambaDownloadTracker.sharedInstance.getAllDownloadedMedia()
    }
    
    func updateMedia(for media: SambaMediaConfig) {
        SambaDownloadTracker.sharedInstance.updateMedia(for: media)
    }
    
    func getOfflineCaption(for mediaID: String) -> SambaMediaCaption? {
        return SambaDownloadTracker.sharedInstance.getOfflineCaption(for: mediaID)
    }
    
}
