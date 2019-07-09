//
//  SambaDownloadManager.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 30/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

@objc public class SambaDownloadManager: NSObject {
    
    @objc public static var sharedInstance = SambaDownloadManager()
    
    private override init() {}
    
    @objc public func config() {
        SambaDownloadTracker.sharedInstance.config(maximumDurationTimeForLicensesOfProtectedContentInMinutes: nil)
    }
    
    @objc public func config(maximumDurationTimeForLicensesOfProtectedContentInMinutes time: Int) {
        SambaDownloadTracker.sharedInstance.config(maximumDurationTimeForLicensesOfProtectedContentInMinutes: time)
    }
    
    @objc public func prepareDownload(with request: SambaDownloadRequest, successCallback: @escaping (_ request: SambaDownloadRequest) -> Void, errorCallback: @escaping (_ error: Error?, _ msg: String) -> Void) {
        SambaDownloadTracker.sharedInstance.prepareDownload(with: request, successCallback: successCallback, errorCallback: errorCallback)
    }
    
    @objc public func performDownload(with request: SambaDownloadRequest) {
        SambaDownloadTracker.sharedInstance.performDownload(with: request)
    }
    
    @objc public func isDownloading(_ mediaID: String) -> Bool {
        return SambaDownloadTracker.sharedInstance.isDownloading(mediaID)
    }
    
    @objc  public func isDownloaded(_ mediaID: String) -> Bool {
        return SambaDownloadTracker.sharedInstance.isDownloaded(mediaID)
    }
    
    @objc public func isPaused(_ mediaId: String) -> Bool {
        return SambaDownloadTracker.sharedInstance.isPaused(mediaId)
    }
    
    @objc public func cancelDownload(for mediaId: String) {
        SambaDownloadTracker.sharedInstance.cancelDownload(for: mediaId)
    }
    
    @objc public func deleteMedia(for mediaId: String) {
        SambaDownloadTracker.sharedInstance.deleteMedia(for: mediaId)
    }
    
    @objc public func deleteAllMedias() {
        SambaDownloadTracker.sharedInstance.deleteAllMedias()
    }
    
    @objc public func cancelAllDownloads() {
        SambaDownloadTracker.sharedInstance.cancelAllDownloads()
    }
    
    @objc public func pauseDownload(for mediaId: String) {
        SambaDownloadTracker.sharedInstance.pauseDownload(for: mediaId)
    }
    
    @objc public func resumeDownload(for mediaId: String) {
        SambaDownloadTracker.sharedInstance.resumeDownload(for: mediaId)
    }
    
    @objc public func pauseAllDownloads()  {
        SambaDownloadTracker.sharedInstance.pauseAllDownloads()
    }
    
    @objc public func resumeAllDownloads()  {
        SambaDownloadTracker.sharedInstance.resumeAllDownloads()
    }
    
    @objc public func getDownloadedMedia(for mediaId: String) -> SambaMedia? {
        return SambaDownloadTracker.sharedInstance.getDownloadedMedia(for: mediaId)
    }
    
    @objc public func getAllDownloadedMedia() -> [SambaMedia] {
        return SambaDownloadTracker.sharedInstance.getAllDownloadedMedia()
    }
    
    func updateMedia(for media: SambaMediaConfig) {
        SambaDownloadTracker.sharedInstance.updateMedia(for: media)
    }
    
    func getOfflineCaption(for mediaID: String) -> SambaMediaCaption? {
        return SambaDownloadTracker.sharedInstance.getOfflineCaption(for: mediaID)
    }
    
}
