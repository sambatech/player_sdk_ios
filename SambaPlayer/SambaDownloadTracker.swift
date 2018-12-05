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
    
    
    fileprivate var sambaMediasPaused: [SambaMediaConfig] = []
    
    // MARK: Intialization
    
    override private init() {
        
        super.init()
        
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: SambaDownloadTracker.DOWNLOAD_ID)
        backgroundConfiguration.allowsCellularAccess = true
        backgroundConfiguration.httpMaximumConnectionsPerHost = 1
        backgroundConfiguration.shouldUseExtendedBackgroundIdleMode = true
        if #available(iOS 11.0, *) {
            backgroundConfiguration.waitsForConnectivity = true
        } 
        
        assetDownloadURLSession = AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                                            assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
        
        sambaMediasDownloading = OfflineUtils.getPersistDownloadingMedias() ?? []
        sambaMediasDownloaded = OfflineUtils.getPersistDownloadedMedias() ?? []
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
         NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
    }
    
    
    @objc func applicationWillResignActive() {
        activeDownloadsMap.forEach { (arg0) in
            
            let (key, _) = arg0
            
            key.suspend()
            key.resume()
            
        }
    }
    
    @objc func applicationWillTerminate() {
        
        activeDownloadsMap.forEach { (arg0) in
            
            let (_, media) = arg0

            cancelDownload(for: media.id)
        }
    }
    
    func restoreTasks() {
        guard !didRestorePersistenceManager else { return }
        
        didRestorePersistenceManager = true
        
        assetDownloadURLSession.getAllTasks { [weak self] tasksArray in
            
            guard let strongSelf = self else {return}
            
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAssetDownloadTask, let media = strongSelf.sambaMediasDownloading.first(where: {$0.id == assetDownloadTask.taskDescription}) else { break }
                
                strongSelf.activeDownloadsMap[assetDownloadTask] = media
                
                strongSelf.cancelDownload(for: media.id)
            }
//            NotificationCenter.default.post(name: .AssetPersistenceManagerDidRestoreState, object: nil)
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
                    sambaMediaConfig.drmRequest?.token = request.drmToken
                    successCallback(request)
                } else {
                    StartDownloadHelper.prepare(request: request, successCallback: successCallback, errorCallback: errorCallback)
                }
                
            }
            
        }) { (error, response) in
            DispatchQueue.main.async {
                errorCallback(error, "Error to resquest Media")
            }
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
            else { return }
        
        
        let downloadUrl = track.output.url
        
        let urlAsset = AVURLAsset(url: downloadUrl)
        
        guard let task = assetDownloadURLSession.makeAssetDownloadTask(asset: urlAsset,
                                                                       assetTitle: sambaMedia.title,
                                                                       assetArtworkData: nil,
                                                                       options: nil) else { return }
        task.taskDescription = sambaMedia.id
        
        
        let downloadState = DownloadState.from(state: DownloadState.State.WAITING, totalDownloadSize: track.sizeInMb, downloadPercentage: 0, media: sambaMedia)
        sambaMedia.downloadData = downloadState.downloadData
        
        activeDownloadsMap[task] = sambaMedia
        
        sambaMediasDownloading.append(sambaMedia)
        
        OfflineUtils.persistDownloadingMedias(sambaMediasDownloading)
        
        task.resume()
        
        OfflineUtils.sendNotification(with: downloadState)
        
    }
    
    //MARK:- Booleans
    
    func isPaused(_ mediaId: String) -> Bool {
        guard sambaMediasPaused.contains(where: { $0.id == mediaId }) else {
            return false
        }
        
        return true
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
            media.isOffline, let _ = OfflineUtils.getMediaLocation(from: media)  else {return false}
        
        return true
    }
    
    func deleteMedia(for mediaId: String) {
        
        guard let media = sambaMediasDownloaded.first(where: {$0.id == mediaId}) else {return}
        
        deleteMediaDownload(media)
    }
    
    func deleteAllMedias() {
        guard let medias = sambaMediasDownloaded, !medias.isEmpty else {
            return
        }
        
        medias.forEach { (media) in
            deleteMediaDownload(media)
        }
    }
    
    
    fileprivate func deleteMediaDownload(_ media: SambaMediaConfig, _ isError: Bool = false, _ isNotify: Bool = true) {
        
        do {
            guard let localFileLocation = OfflineUtils.localAssetForMedia(withMedia: media)?.url else {
                return
            }
            
            try FileManager.default.removeItem(at: localFileLocation)
                
            OfflineUtils.removeMediaLocation(from: media)
            sambaMediasDownloaded.removeAll(where: {$0.id == media.id})
            OfflineUtils.persistDownloadedMedias(sambaMediasDownloaded)
            
            
            if isNotify {
                let downloadState = DownloadState.from(state: isError ? DownloadState.State.FAILED : DownloadState.State.DELETED , totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media)
                
                OfflineUtils.sendNotification(with: downloadState)
            }
         
        } catch {
            print("An error occured deleting the file: \(error)")
        }
    }
    
    func cancelDownload(for mediaId: String) {
        
        guard let _ = sambaMediasDownloading.first(where: {$0.id == mediaId}) else {return}
        
        var task: AVAssetDownloadTask?
        
        for (taskKey, mediaDownloading) in activeDownloadsMap where mediaDownloading.id == mediaId {
            task = taskKey
            break
        }
        
        task?.cancel()
        
        sambaMediasDownloading.removeAll(where: {$0.id == mediaId})
        OfflineUtils.persistDownloadingMedias(sambaMediasDownloading)
    }
    
    func cancelAllDownloads() {
        guard let medias = sambaMediasDownloading, !medias.isEmpty else {return}
        
        medias.forEach { media in
            cancelDownload(for: media.id)
        }
    }
    
    func pauseDownload(for mediaId: String) {
         guard !activeDownloadsMap.isEmpty, !sambaMediasPaused.contains(where: {$0.id == mediaId}),
            let values = activeDownloadsMap.first(where: {$1.id == mediaId})
            else {return}
        
        let task = values.key
        let media = values.value
        
        task.suspend()
        
        sambaMediasPaused.append(media)
        
        let downloadState = DownloadState.from(state: DownloadState.State.PAUSED, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media)
            
        OfflineUtils.sendNotification(with: downloadState)
        
    }
    
    func resumeDownload(for mediaId: String) {
        guard !activeDownloadsMap.isEmpty, sambaMediasPaused.contains(where: {$0.id == mediaId}),
            let values = activeDownloadsMap.first(where: {$1.id == mediaId})
            else {return}
        
        let task = values.key
        let media = values.value
        
        task.resume()
        
        sambaMediasPaused.removeAll(where: {$0.id == mediaId})
        
        let downloadState = DownloadState.from(state: DownloadState.State.RESUMED, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media)
            
        OfflineUtils.sendNotification(with: downloadState)
        
    }
    
    
    func pauseAllDownloads()  {
        guard let medias = sambaMediasDownloading, !medias.isEmpty else {return}
        
        medias.forEach { media in
            pauseDownload(for: media.id)
        }
    }
    
    func resumeAllDownloads()  {
        guard let medias = sambaMediasDownloading, !medias.isEmpty else {return}
        
        medias.forEach { media in
            resumeDownload(for: media.id)
        }
    }

    
    fileprivate func nextMediaSelection(_ asset: AVURLAsset) -> (mediaSelectionGroup: AVMediaSelectionGroup?,
        mediaSelectionOption: AVMediaSelectionOption?) {
            guard #available(iOS 10.0, *),
                let assetCache = asset.assetCache else { return (nil, nil) }
            
            let mediaCharacteristics = [AVMediaCharacteristicAudible, AVMediaCharacteristicLegible]
            
            for mediaCharacteristic in mediaCharacteristics {
                if let mediaSelectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic) {
                    let savedOptions = assetCache.mediaSelectionOptions(in: mediaSelectionGroup)
                    
                    if savedOptions.count < mediaSelectionGroup.options.count {
                        // There are still media options left to download.
                        for option in mediaSelectionGroup.options {
                            if !savedOptions.contains(option) && option.mediaType != AVMediaTypeClosedCaption {
                                // This option has not been download.
                                return (mediaSelectionGroup, option)
                            }
                        }
                    }
                }
            }
            
            // At this point all media options have been downloaded.
            return (nil, nil)
    }
    
}


//MARK: - Delegate Download Asset
extension SambaDownloadTracker: AVAssetDownloadDelegate {
    
    /// Tells the delegate that the task finished transferring data.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                /*
                 This is the ideal place to begin downloading additional media selections
                 once the asset itself has finished downloading.
                 */
                guard let task = task as? AVAssetDownloadTask, let media = activeDownloadsMap.removeValue(forKey: task) else { return }
        
                sambaMediasDownloading.removeAll(where: {$0.id == media.id})
                OfflineUtils.persistDownloadingMedias(sambaMediasDownloading)
        
                // Prepare the basic userInfo dictionary that will be posted as part of our notification.
                var downloadState: DownloadState!
                var isError = true
        
                if let error = error as NSError? {
                    switch (error.domain, error.code) {
                        case (NSURLErrorDomain, NSURLErrorCancelled):
                            print("Downloading was canceled with erro domain")
                            isError = false
                        case (NSURLErrorDomain, NSURLErrorUnknown):
                            print("Downloading HLS streams is not supported in the simulator.")
            
                        default:
                            print("An unexpected error occured \(error.domain)")
                    }
                    
                    deleteMediaDownload(media, isError, false)

                    downloadState = DownloadState.from(state: isError ? DownloadState.State.FAILED : DownloadState.State.CANCELED, totalDownloadSize: 0, downloadPercentage: 0, media: media)
                    
                } else {
                    let mediaSelectionPair = nextMediaSelection(task.urlAsset)
        
                    if mediaSelectionPair.mediaSelectionGroup != nil {
                        /*
                         This task did complete sucessfully. At this point the application
                         can download additional media selections if needed.
        
                         To download additional `AVMediaSelection`s, you should use the
                         `AVMediaSelection` reference saved in `AVAssetDownloadDelegate.urlSession(_:assetDownloadTask:didResolve:)`.
                         */
        
                        guard let originalMediaSelection = mediaSelectionMap[task] else { return }
        
                        /*
                         There are still media selections to download.
        
                         Create a mutable copy of the AVMediaSelection reference saved in
                         `AVAssetDownloadDelegate.urlSession(_:assetDownloadTask:didResolve:)`.
                         */
                        let mediaSelection = originalMediaSelection.mutableCopy() as! AVMutableMediaSelection
        
                        // Select the AVMediaSelectionOption in the AVMediaSelectionGroup we found earlier.
                        mediaSelection.select(mediaSelectionPair.mediaSelectionOption!,
                                              in: mediaSelectionPair.mediaSelectionGroup!)
        
                        /*
                         Ask the `URLSession` to vend a new `AVAssetDownloadTask` using
                         the same `AVURLAsset` and assetTitle as before.
        
                         This time, the application includes the specific `AVMediaSelection`
                         to download as well as a higher bitrate.
                         */
                        guard #available(iOS 10.0, *), let task = assetDownloadURLSession.makeAssetDownloadTask(asset: task.urlAsset,
                                                                                       assetTitle: media.title,
                                                                                       assetArtworkData: nil,
                                                                                       options: [AVAssetDownloadTaskMediaSelectionKey: mediaSelection])
                            else { return }
        
                        task.taskDescription = media.id
        
                        let downloadState = DownloadState.from(state: DownloadState.State.WAITING, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media)
                        media.downloadData = downloadState.downloadData
                        
                        activeDownloadsMap[task] = media
                        
                        sambaMediasDownloading.append(media)
                        
                        OfflineUtils.persistDownloadingMedias(sambaMediasDownloading)
                        
                        task.resume()
    
                    } else {
                         downloadState = DownloadState.from(state: DownloadState.State.COMPLETED, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 100, media: media)
                    }
                }
        
                OfflineUtils.sendNotification(with: downloadState)
    
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        guard let media = activeDownloadsMap[assetDownloadTask] else {
            return
        }

        do {
            let bookmark = try location.bookmarkData()
            OfflineUtils.saveMediaLocation(with: media, location: bookmark)
            media.isOffline = true
                
            if !sambaMediasDownloaded.contains(where: {$0.id == media.id}) {
                sambaMediasDownloaded.append(media)
            } else {
                let newMedia = sambaMediasDownloaded.filter({$0.id == media.id})
                newMedia.forEach({$0.isOffline = true})
            }
                
                
            OfflineUtils.persistDownloadedMedias(sambaMediasDownloaded)
            
        } catch {
                print("Failed to create bookmark for location: \(location)")
                deleteMediaDownload(media, true)
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        
        guard let media = activeDownloadsMap[assetDownloadTask],
         !sambaMediasPaused.contains(where: {$0.id == media.id}) else { return }
        
        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete += CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        }
        
        let downloadState = DownloadState.from(state: DownloadState.State.IN_PROGRESS, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: Float(percentComplete), media: media, sambaSubtitle: nil)
        
        OfflineUtils.sendNotification(with: downloadState)
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didResolve resolvedMediaSelection: AVMediaSelection) {
        
        mediaSelectionMap[assetDownloadTask] = resolvedMediaSelection
        
    }
    
    
}


extension Notification.Name {
    
    public static let SambaDownloadStateChanged = Notification.Name(rawValue: "SambaDownloadStateChangedNotification")
    
    static let SambaDidRestoreState = Notification.Name(rawValue: "SambaDidRestoreState")
}

