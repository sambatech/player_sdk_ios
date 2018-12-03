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
    
    fileprivate var sambaMediasDownloading: [SambaMediaConfig]!
    fileprivate var sambaMediasDownloaded: [SambaMediaConfig]!
    
    // MARK: Intialization
    
    override private init() {
        
        super.init()
        
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: SambaDownloadTracker.DOWNLOAD_ID)
        
        
        assetDownloadURLSession = AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                                            assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
        
        sambaMediasDownloading = OfflineUtils.getPersistDownloadingMedias() ?? []
        sambaMediasDownloaded = OfflineUtils.getPersistDownloadedMedias() ?? []
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
    }
    
    
    @objc func applicationWillResignActive() {
        activeDownloadsMap.forEach { (arg0) in
            
            let (key, value) = arg0
            
            key.suspend()
            key.resume()
            
        }
    }
    
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
        
        guard #available(iOS 10.0, *),
            let sambaMedia = request.sambaMedia as? SambaMediaConfig,
            let track = request.sambaTrackForDownload
            else {
                return
        }
        
        
        let downloadUrl = track.output.url
        
        let urlAsset = AVURLAsset(url: downloadUrl)
    
        guard let task = assetDownloadURLSession.makeAssetDownloadTask(asset: urlAsset,
                                                                           assetTitle: sambaMedia.title,
                                                                           assetArtworkData: nil,
                                                                           options: nil) else { return }
        task.taskDescription = sambaMedia.id
        activeDownloadsMap[task] = sambaMedia
        
        sambaMediasDownloading.append(sambaMedia)
        OfflineUtils.persistDownloadingMedias(sambaMediasDownloading)
        
        task.resume()
        
        var userInfo = [DownloadState.Key: Any]()
        
        

        userInfo[DownloadState.Key.state] = DownloadState.from(state: DownloadState.State.WAITING, totalDownloadSize: track.sizeInMb, downloadPercentage: 0, media: sambaMedia)

        NotificationCenter.default.post(name: .SambaDownloadStateChanged, object: nil, userInfo: userInfo)

    }
    
    func isDownloading(_ mediaId: String) -> Bool {
        guard activeDownloadsMap.contains(where: { $1.id == mediaId }),
            sambaMediasDownloading.contains(where: { $0.id == mediaId}) else {
            return false
        }
        
        return true
    }
    
    func isDownloaded(_ mediaId: String) -> Bool {
        
        guard let media = sambaMediasDownloaded.first(where: { $0.id == mediaId }),
            let path = media.offlinePath, !path.isEmpty  else {return false}
        
        return true
    }
    
}


extension SambaDownloadTracker: AVAssetDownloadDelegate {
    
    /// Tells the delegate that the task finished transferring data.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        //        let userDefaults = UserDefaults.standard
        //
        //        /*
        //         This is the ideal place to begin downloading additional media selections
        //         once the asset itself has finished downloading.
        //         */
        //        guard let task = task as? AVAssetDownloadTask, let asset = activeDownloadsMap.removeValue(forKey: task) else { return }
        //
        //        // Prepare the basic userInfo dictionary that will be posted as part of our notification.
        //        var userInfo = [String: Any]()
        //        userInfo[Asset.Keys.name] = asset.stream.name
        //
        //        if let error = error as NSError? {
        //            switch (error.domain, error.code) {
        //            case (NSURLErrorDomain, NSURLErrorCancelled):
        //                /*
        //                 This task was canceled, you should perform cleanup using the
        //                 URL saved from AVAssetDownloadDelegate.urlSession(_:assetDownloadTask:didFinishDownloadingTo:).
        //                 */
        //                guard let localFileLocation = localAssetForStream(withName: asset.stream.name)?.urlAsset.url else { return }
        //
        //                do {
        //                    try FileManager.default.removeItem(at: localFileLocation)
        //
        //                    userDefaults.removeObject(forKey: asset.stream.name)
        //                } catch {
        //                    print("An error occured trying to delete the contents on disk for \(asset.stream.name): \(error)")
        //                }
        //
        //                userInfo[Asset.Keys.downloadState] = Asset.DownloadState.notDownloaded.rawValue
        //
        //            case (NSURLErrorDomain, NSURLErrorUnknown):
        //                fatalError("Downloading HLS streams is not supported in the simulator.")
        //
        //            default:
        //                fatalError("An unexpected error occured \(error.domain)")
        //            }
        //        } else {
        //            let mediaSelectionPair = nextMediaSelection(task.urlAsset)
        //
        //            if mediaSelectionPair.mediaSelectionGroup != nil {
        //                /*
        //                 This task did complete sucessfully. At this point the application
        //                 can download additional media selections if needed.
        //
        //                 To download additional `AVMediaSelection`s, you should use the
        //                 `AVMediaSelection` reference saved in `AVAssetDownloadDelegate.urlSession(_:assetDownloadTask:didResolve:)`.
        //                 */
        //
        //                guard let originalMediaSelection = mediaSelectionMap[task] else { return }
        //
        //                /*
        //                 There are still media selections to download.
        //
        //                 Create a mutable copy of the AVMediaSelection reference saved in
        //                 `AVAssetDownloadDelegate.urlSession(_:assetDownloadTask:didResolve:)`.
        //                 */
        //                let mediaSelection = originalMediaSelection.mutableCopy() as! AVMutableMediaSelection
        //
        //                // Select the AVMediaSelectionOption in the AVMediaSelectionGroup we found earlier.
        //                mediaSelection.select(mediaSelectionPair.mediaSelectionOption!,
        //                                      in: mediaSelectionPair.mediaSelectionGroup!)
        //
        //                /*
        //                 Ask the `URLSession` to vend a new `AVAssetDownloadTask` using
        //                 the same `AVURLAsset` and assetTitle as before.
        //
        //                 This time, the application includes the specific `AVMediaSelection`
        //                 to download as well as a higher bitrate.
        //                 */
        //                guard let task = assetDownloadURLSession.makeAssetDownloadTask(asset: task.urlAsset,
        //                                                                               assetTitle: asset.stream.name,
        //                                                                               assetArtworkData: nil,
        //                                                                               options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 2_000_000,
        //                                                                                         AVAssetDownloadTaskMediaSelectionKey: mediaSelection])
        //                    else { return }
        //
        //                task.taskDescription = asset.stream.name
        //
        //                activeDownloadsMap[task] = asset
        //
        //                task.resume()
        //
        //                userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloading.rawValue
        //                userInfo[Asset.Keys.downloadSelectionDisplayName] = mediaSelectionPair.mediaSelectionOption!.displayName
        //
        //                NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
        //            } else {
        //                // All additional media selections have been downloaded.
        //
        //                userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloaded.rawValue
        //
        //            }
        //        }
        //
        //        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
        //    }
        //
        //    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
        //                    didFinishDownloadingTo location: URL) {
        //        let userDefaults = UserDefaults.standard
        //
        //        /*
        //         This delegate callback should only be used to save the location URL
        //         somewhere in your application. Any additional work should be done in
        //         `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
        //         */
        //        if let asset = activeDownloadsMap[assetDownloadTask] {
        //
        //            do {
        //                let bookmark = try location.bookmarkData()
        //
        //                userDefaults.set(bookmark, forKey: asset.stream.name)
        //            } catch {
        //                print("Failed to create bookmark for location: \(location)")
        //                deleteAsset(asset)
        //            }
        //        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        //        // This delegate callback should be used to provide download progress for your AVAssetDownloadTask.
        //        guard let asset = activeDownloadsMap[assetDownloadTask] else { return }
        //
        //        var percentComplete = 0.0
        //        for value in loadedTimeRanges {
        //            let loadedTimeRange: CMTimeRange = value.timeRangeValue
        //            percentComplete +=
        //                CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        //        }
        //
        //        var userInfo = [String: Any]()
        //        userInfo[Asset.Keys.name] = asset.stream.name
        //        userInfo[Asset.Keys.percentDownloaded] = percentComplete
        //
        //        NotificationCenter.default.post(name: .AssetDownloadProgress, object: nil, userInfo: userInfo)
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didResolve resolvedMediaSelection: AVMediaSelection) {
  
        mediaSelectionMap[assetDownloadTask] = resolvedMediaSelection
        
    }
    
    
}


extension Notification.Name {
   
    static let SambaDownloadProgress = Notification.Name(rawValue: "SambaDownloadProgressNotification")
    
    static let SambaDownloadStateChanged = Notification.Name(rawValue: "SambaDownloadStateChangedNotification")

    static let SambaPersistenceManagerDidRestoreState = Notification.Name(rawValue: "SambaPersistenceManagerDidRestoreStateNotification")
}

