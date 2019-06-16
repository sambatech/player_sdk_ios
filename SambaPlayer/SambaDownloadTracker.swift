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
    private static let DOWNLOAD_PROGRESSIVE_ID = "SAMBA_PLAYER_DOWNLOAD_PROGRESSIVE_ID"
    private static let DOWNLOAD_SUBTITLE_ID = "SAMBA_PLAYER_DOWNLOAD_SUBTITLE_ID"
    
    static let sharedInstance = SambaDownloadTracker()
    
    /// Internal Bool used to track if the AssetPersistenceManager finished restoring its state.
    private var didRestorePersistenceManager = false
    
    /// The AVAssetDownloadURLSession to use for managing AVAssetDownloadTasks.
    fileprivate var assetDownloadURLSession: AVAssetDownloadURLSession!
    
    fileprivate var progressiveDownloadURLSession: URLSession!
    fileprivate var subtitlesDownloadURLSession: URLSession!
    
    /// Internal map of AVAssetDownloadTask to its corresponding Asset.
    fileprivate var activeDownloadsMap = [URLSessionTask: SambaMediaConfig]()
    fileprivate var captionsForDownloadsMap = [URLSessionTask: SambaSubtitle]()
    
    /// Internal map of AVAssetDownloadTask to its resoled AVMediaSelection
    fileprivate var mediaSelectionMap = [AVAssetDownloadTask: AVMediaSelection]()
    
    fileprivate var sambaMediasDownloading: [SambaMediaConfig]!
    fileprivate var sambaMediasDownloaded: [SambaMediaConfig]!
    
    fileprivate var sambaSubtitlesDownloading: [SambaSubtitle]!
    fileprivate var sambaSubtitlesDownloaded: [SambaSubtitle]!
    
    
    fileprivate var sambaMediasPaused: [SambaMediaConfig] = []
    fileprivate var sambaSubtitlesPaused: [SambaSubtitle] = []
    
    private var _decryptDelegate: AssetLoaderDelegate?
    private var _decryptDelegateAES: AESAssetLoaderDelegate?
    
    private var _downloadProgressiveDelegate: DownloadProgressiveDelegate?
    private var _downloadSubtitlesDelegate: DownloadSubtitlesDelegate?
    
    private(set) var maximumDurationTimeForLicensesOfProtectedContentInMinutes: Double?
    
    // MARK: Intialization
    
    override private init() {
        
        super.init()
        
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: SambaDownloadTracker.DOWNLOAD_ID)
        
        assetDownloadURLSession = AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                                            assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
        
        
        
        let backgroundConfigurationProgressive = URLSessionConfiguration.background(withIdentifier: SambaDownloadTracker.DOWNLOAD_PROGRESSIVE_ID)
        
        _downloadProgressiveDelegate = DownloadProgressiveDelegate(master: self)
        progressiveDownloadURLSession = URLSession(configuration: backgroundConfigurationProgressive, delegate: _downloadProgressiveDelegate, delegateQueue: OperationQueue.main)
        
        
        let backgroundConfigurationSubtitle = URLSessionConfiguration.background(withIdentifier: SambaDownloadTracker.DOWNLOAD_SUBTITLE_ID)
        
        _downloadSubtitlesDelegate = DownloadSubtitlesDelegate(master: self)
        subtitlesDownloadURLSession = URLSession(configuration: backgroundConfigurationSubtitle, delegate: _downloadSubtitlesDelegate, delegateQueue: OperationQueue.main)
        
        
        
        sambaMediasDownloading = OfflineUtils.getPersistDownloadingMedias() ?? []
        sambaMediasDownloaded = OfflineUtils.getPersistDownloadedMedias() ?? []
        
        sambaSubtitlesDownloaded = OfflineUtils.getPersistDownloadedSubtitles() ?? []
        sambaSubtitlesDownloading = OfflineUtils.getPersistDownloadingSubtitles() ?? []
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        
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
    
    func config(maximumDurationTimeForLicensesOfProtectedContentInMinutes time: Int? = nil) {
        
        if let time = time {
            self.maximumDurationTimeForLicensesOfProtectedContentInMinutes = Double(time)
        } else {
            self.maximumDurationTimeForLicensesOfProtectedContentInMinutes = nil
        }
        
        guard !didRestorePersistenceManager else { return }
        
        didRestorePersistenceManager = true
        
        assetDownloadURLSession.getAllTasks { [weak self] tasksArray in
            
            guard let strongSelf = self else {return}
            
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAssetDownloadTask, let media = strongSelf.sambaMediasDownloading.first(where: {$0.id == assetDownloadTask.taskDescription}) else { break }
                
                strongSelf.activeDownloadsMap[assetDownloadTask] = media
                
                strongSelf.cancelDownload(for: media.id)
            }
        }
        
        progressiveDownloadURLSession.getAllTasks { [weak self] tasksArray in
            
            guard let strongSelf = self else {return}
            
            for task in tasksArray {
                guard let assetDownloadTask = task as? URLSessionDownloadTask, let media = strongSelf.sambaMediasDownloading.first(where: {$0.id == assetDownloadTask.taskDescription}) else { break }
                
                strongSelf.activeDownloadsMap[assetDownloadTask] = media
                
                strongSelf.cancelDownload(for: media.id)
            }
        }
        
        
        subtitlesDownloadURLSession.getAllTasks { [weak self] tasksArray in
            
            guard let strongSelf = self else {return}
            
            for task in tasksArray {
                guard let assetDownloadTask = task as? URLSessionDownloadTask, let subtitle = strongSelf.sambaSubtitlesDownloading.first(where: {"SUB_\($0.mediaID)" == assetDownloadTask.taskDescription}) else { break }
                
                strongSelf.captionsForDownloadsMap[assetDownloadTask] = subtitle
                
                strongSelf.cancelDownload(for: subtitle.mediaID)
            }
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
                
                if let _ = sambaMediaConfig.drmRequest {
                    sambaMediaConfig.drmRequest?.token = request.drmToken
                }
                
                StartDownloadHelper.prepare(request: request, successCallback: successCallback, errorCallback: errorCallback)
                
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
        
        
        var task: URLSessionTask!
        
        if !track.isProgressive {
            let urlAsset = AVURLAsset(url: downloadUrl)
            task = assetDownloadURLSession.makeAssetDownloadTask(asset: urlAsset,
                                                                           assetTitle: sambaMedia.title,
                                                                           assetArtworkData: nil,
                                                                           options: nil)
            if sambaMedia.drmRequest != nil {
                _decryptDelegate = AssetLoaderDelegate(asset: urlAsset, assetName: sambaMedia.id, drmRequest: sambaMedia.drmRequest!, isForPersist: true)
            }
            
            //        else {
            //            var components = URLComponents(url: downloadUrl, resolvingAgainstBaseURL: true)
            //            let scheme = components?.scheme
            //            components?.scheme = "fakehttps"
            //            _decryptDelegateAES = AESAssetLoaderDelegate(asset: AVURLAsset(url: (components?.url)!), assetName: sambaMedia.id, previousScheme: scheme!)
            //        }
            
        } else {
           task = progressiveDownloadURLSession.downloadTask(with: downloadUrl)
        }
        
        sambaMedia.offlineUrl = downloadUrl.absoluteString
        
        task.taskDescription = sambaMedia.id
        
        
        let downloadState = DownloadState.from(state: DownloadState.State.WAITING, totalDownloadSize: track.sizeInMb, downloadPercentage: 0, media: sambaMedia)
        sambaMedia.downloadData = downloadState.downloadData
        
        activeDownloadsMap[task] = sambaMedia
        
        sambaMediasDownloading.append(sambaMedia)
        
        OfflineUtils.persistDownloadingMedias(sambaMediasDownloading)
        
        
        if let subtitle = request.sambaSubtitleForDownload, let subURL = URL(string: subtitle.caption.url) {
            let subtitleTask = subtitlesDownloadURLSession.downloadTask(with: subURL)
            subtitleTask.taskDescription = "SUB_\(subtitle.mediaID)"
            captionsForDownloadsMap[subtitleTask] = subtitle
        }
        
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
        
        if let subtitle = sambaSubtitlesDownloaded.first(where: {$0.mediaID == mediaId}) {
            deleteSubtitleDownload(subtitle)
        }
        
        deleteMediaDownload(media)
    }
    
    func deleteAllMedias() {
        guard let medias = sambaMediasDownloaded, !medias.isEmpty else {
            return
        }
        
        if let subtitles = sambaSubtitlesDownloaded, !subtitles.isEmpty {
            subtitles.forEach { (subtitle) in
                deleteSubtitleDownload(subtitle)
            }
        }
        
        medias.forEach { (media) in
            deleteMediaDownload(media)
        }
    }
    
    func getDownloadedMedia(for mediaId: String) -> SambaMedia? {
        return sambaMediasDownloaded.first(where: {$0.id == mediaId})
    }
    
    func getAllDownloadedMedia() -> [SambaMedia] {
        return sambaMediasDownloaded
    }
    
    func getOfflineCaption(for mediaID: String) -> SambaMediaCaption? {
        guard let subtitles = sambaSubtitlesDownloaded, !subtitles.isEmpty,
        let subtitle = sambaSubtitlesDownloaded.first(where: {$0.mediaID == mediaID}) else {
            return nil
        }
        
        return SambaMediaCaption(
            url: OfflineUtils.loadURLForOfflineSubtitle(with: subtitle)?.absoluteString ?? subtitle.caption.url,
            label: subtitle.caption.label,
            language: subtitle.caption.language,
            cc: subtitle.caption.cc,
            isDefault: subtitle.caption.isDefault
        )
    }
    
    fileprivate func deleteMediaDownload(_ media: SambaMediaConfig, _ isError: Bool = false, _ isNotify: Bool = true) {
        
        do {
            guard let localFileLocation = OfflineUtils.localAssetForMedia(withMedia: media)?.url else {
                sambaMediasDownloaded.removeAll(where: {$0.id == media.id})
                OfflineUtils.persistDownloadedMedias(sambaMediasDownloaded)
                if isNotify {
                    let downloadState = DownloadState.from(state: isError ? DownloadState.State.FAILED : DownloadState.State.DELETED , totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media)
                    
                    OfflineUtils.sendNotification(with: downloadState)
                }
                return
            }
            
            if let drmRequest = media.drmRequest {
                let assetDelegate = AssetLoaderDelegate(asset: AVURLAsset(url: localFileLocation), assetName: media.id, drmRequest: drmRequest)
                assetDelegate.deletePersistedConentKeyForAsset()
            }
            
            try FileManager.default.removeItem(at: localFileLocation)
            
            OfflineUtils.removeMediaLocation(from: media)
         
        } catch {
            print("An error occured deleting the file: \(error)")
            
        }
        
        sambaMediasDownloaded.removeAll(where: {$0.id == media.id})
        OfflineUtils.persistDownloadedMedias(sambaMediasDownloaded)
        
        
        if isNotify {
            let downloadState = DownloadState.from(state: isError ? DownloadState.State.FAILED : DownloadState.State.DELETED , totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media)
            
            OfflineUtils.sendNotification(with: downloadState)
        }
    }
    
    
    fileprivate func deleteSubtitleDownload(_ subtitle: SambaSubtitle, _ isError: Bool = false, _ isNotify: Bool = true) {
        
        do {
            guard let localFileLocation = OfflineUtils.loadURLForOfflineSubtitle(with: subtitle) else {
                return
            }
            
            
            try FileManager.default.removeItem(at: localFileLocation)
            
            OfflineUtils.removeSubtitleLocation(from: subtitle)
            
            sambaSubtitlesDownloaded.removeAll(where: {$0.mediaID == subtitle.mediaID})
            OfflineUtils.persistDownloadedSubtitles(sambaSubtitlesDownloaded)
            
            if isNotify, let media = sambaMediasDownloaded.first(where: {$0.id == subtitle.mediaID}) {
                let downloadState = DownloadState.from(state: isError ? DownloadState.State.FAILED : DownloadState.State.DELETED , totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media)
                
                OfflineUtils.sendNotification(with: downloadState)
            }
            
        } catch {
            print("An error occured deleting the file: \(error)")
        }
    }
    
    func cancelDownload(for mediaId: String) {
        
        if  sambaMediasDownloading.contains(where: {$0.id == mediaId})  {
            var task: URLSessionTask?
            
            for (taskKey, mediaDownloading) in activeDownloadsMap where mediaDownloading.id == mediaId {
                task = taskKey
                break
            }
            
            task?.cancel()
            
            sambaMediasDownloading.removeAll(where: {$0.id == mediaId})
            OfflineUtils.persistDownloadingMedias(sambaMediasDownloading)
            sambaMediasPaused.removeAll(where: {$0.id == mediaId})
            
            
            // Remove Subtitles
            var taskSub: URLSessionTask?
            
            for (taskKey, subtitleDownloading) in captionsForDownloadsMap where subtitleDownloading.mediaID == mediaId {
                taskSub = taskKey
                break
            }
            
            taskSub?.cancel()
            
            sambaSubtitlesDownloading.removeAll(where: {$0.mediaID == mediaId})
            OfflineUtils.persistDownloadingSubtitles(sambaSubtitlesDownloading)
            sambaSubtitlesPaused.removeAll(where: {$0.mediaID == mediaId})
            
            
        } else if sambaSubtitlesDownloading.contains(where: {$0.mediaID == mediaId}) {
            var task: URLSessionTask?
            
            for (taskKey, subtitleDownloading) in captionsForDownloadsMap where subtitleDownloading.mediaID == mediaId {
                task = taskKey
                break
            }
            
            task?.cancel()
            
            sambaSubtitlesDownloading.removeAll(where: {$0.mediaID == mediaId})
            OfflineUtils.persistDownloadingSubtitles(sambaSubtitlesDownloading)
            sambaSubtitlesPaused.removeAll(where: {$0.mediaID == mediaId})
            
            guard let media = sambaMediasDownloaded.first(where: {$0.id == mediaId}) else {return}
            
            deleteMediaDownload(media, false, false)
        }
        
    }
    
    func cancelAllDownloads() {
        guard let medias = sambaMediasDownloading, !medias.isEmpty else {return}
        
        medias.forEach { media in
            cancelDownload(for: media.id)
        }
    }
    
    func pauseDownload(for mediaId: String) {
         guard (!activeDownloadsMap.isEmpty && !sambaMediasPaused.contains(where: {$0.id == mediaId}))
            || (!captionsForDownloadsMap.isEmpty && !sambaSubtitlesPaused.contains(where: {$0.mediaID == mediaId}))
            else {return}
        
        
        if !sambaMediasPaused.contains(where: {$0.id == mediaId}), let pairMedia = activeDownloadsMap.first(where: {$1.id == mediaId}) {
            let task = pairMedia.key
            let media = pairMedia.value
            
            task.suspend()
            
            sambaMediasPaused.append(media)
            
            let downloadState = DownloadState.from(state: DownloadState.State.PAUSED, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media)
            
            OfflineUtils.sendNotification(with: downloadState)
        } else if !sambaSubtitlesPaused.contains(where: {$0.mediaID == mediaId}), let pairSubtitle = captionsForDownloadsMap.first(where: {$1.mediaID == mediaId}) {
            let task = pairSubtitle.key
            let subtitle = pairSubtitle.value
            
            guard let media = sambaMediasDownloaded.first(where: {$0.id == mediaId}) else {
                deleteMedia(for: mediaId)
                return
            }
            
            task.suspend()
            
            sambaSubtitlesPaused.append(subtitle)
            
            let downloadState = DownloadState.from(state: DownloadState.State.PAUSED, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media, sambaSubtitle: subtitle )
            
            OfflineUtils.sendNotification(with: downloadState)
        }
        
    }
    
    func resumeDownload(for mediaId: String) {
        
        guard (!activeDownloadsMap.isEmpty && sambaMediasPaused.contains(where: {$0.id == mediaId}))
            || (!captionsForDownloadsMap.isEmpty && sambaSubtitlesPaused.contains(where: {$0.mediaID == mediaId})) else {return}
        
        if let pairMedia = activeDownloadsMap.first(where: {$1.id == mediaId}) {
            let task = pairMedia.key
            let media = pairMedia.value
            
            task.resume()
            
            sambaMediasPaused.removeAll(where: {$0.id == mediaId})
            
            let downloadState = DownloadState.from(state: DownloadState.State.RESUMED, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media)
            
            OfflineUtils.sendNotification(with: downloadState)
        } else if let pairSubtitle = captionsForDownloadsMap.first(where: {$1.mediaID == mediaId}) {
            let task = pairSubtitle.key
            let subtitle = pairSubtitle.value
            
            task.resume()
            
            sambaSubtitlesPaused.removeAll(where: {$0.mediaID == subtitle.mediaID})
            
            guard let media = sambaMediasDownloaded.first(where: {$0.id == mediaId}) else {
                deleteMedia(for: mediaId)
                return
            }
            
            
            let downloadState = DownloadState.from(state: DownloadState.State.RESUMED, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 0, media: media, sambaSubtitle: subtitle)
            
            OfflineUtils.sendNotification(with: downloadState)
        }
        
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
    
    func updateMedia(for media: SambaMediaConfig) {
        
        guard let oldMediaIndex = sambaMediasDownloaded.firstIndex(where: {$0.id == media.id}) else {
            return
        }
        
        sambaMediasDownloaded[oldMediaIndex] = media
        
        OfflineUtils.persistDownloadedMedias(sambaMediasDownloaded)
        
    }

    
    fileprivate func nextMediaSelection(_ asset: AVURLAsset) -> (mediaSelectionGroup: AVMediaSelectionGroup?,
        mediaSelectionOption: AVMediaSelectionOption?) {
            guard #available(iOS 10.0, *),
                let assetCache = asset.assetCache else { return (nil, nil) }
            
            let mediaCharacteristics = [AVMediaCharacteristic.audible, AVMediaCharacteristic.legible]
            
            for mediaCharacteristic in mediaCharacteristics {
                if let mediaSelectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic) {
                    let savedOptions = assetCache.mediaSelectionOptions(in: mediaSelectionGroup)
                    
                    if savedOptions.count < mediaSelectionGroup.options.count {
                        // There are still media options left to download.
                        for option in mediaSelectionGroup.options {
                            if !savedOptions.contains(option) && option.mediaType != AVMediaType.closedCaption {
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



//MARK: - Delegate Download Progressive
class DownloadProgressiveDelegate: NSObject, URLSessionDownloadDelegate {
    
    var master: SambaDownloadTracker!
    
    init(master: SambaDownloadTracker) {
        self.master = master;
    }
    
    /// Tells the delegate that the task finished transferring data.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
       
        guard let task = task as? URLSessionDownloadTask, let media = master.activeDownloadsMap.removeValue(forKey: task) else { return }
        
        master.sambaMediasDownloading.removeAll(where: {$0.id == media.id})
        OfflineUtils.persistDownloadingMedias(master.sambaMediasDownloading)
        master.sambaMediasPaused.removeAll(where: {$0.id == media.id})
        
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
            
            master.deleteMediaDownload(media, isError, false)
            
            downloadState = DownloadState.from(state: isError ? DownloadState.State.FAILED : DownloadState.State.CANCELED, totalDownloadSize: 0, downloadPercentage: 0, media: media)
            OfflineUtils.sendNotification(with: downloadState)
        } else {
            if let pairSub = master.captionsForDownloadsMap.first(where: {$1.mediaID == media.id}) {
                let taskSub = pairSub.key
                taskSub.resume()
            } else {
                 downloadState = DownloadState.from(state: DownloadState.State.COMPLETED, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 100, media: media)
                 OfflineUtils.sendNotification(with: downloadState)
            }
            
        }
    }
    
    
   
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
         print("a")
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)  {
        
        guard let media = master.activeDownloadsMap[downloadTask] else {
            return
        }
        
        do {
            
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            
            let extensionFile = URL(string: media.offlineUrl ?? "")?.pathExtension ?? "mp3"
            
            let destinationUrl = documentsUrl.appendingPathComponent("\(media.id).\(extensionFile)")
            guard let dataFromURL = try? Data(contentsOf: location) else {
               master.deleteMediaDownload(media, true)
               return
            }
            
            try dataFromURL.write(to: destinationUrl, options: .atomic)
            
            let bookmark = try destinationUrl.bookmarkData()
            
            OfflineUtils.saveMediaLocation(with: media, location: bookmark)
            media.isOffline = true
            
            if !master.sambaMediasDownloaded.contains(where: {$0.id == media.id}) {
                master.sambaMediasDownloaded.append(media)
            } else {
                let newMedia = master.sambaMediasDownloaded.filter({$0.id == media.id})
                newMedia.forEach({$0.isOffline = true})
            }
            
            
            OfflineUtils.persistDownloadedMedias(master.sambaMediasDownloaded)
            
        } catch {
            print("Failed to create bookmark for location: \(location)")
            master.deleteMediaDownload(media, true)
        }
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let media = master.activeDownloadsMap[downloadTask],
            !master.sambaMediasPaused.contains(where: {$0.id == media.id}) else { return }
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        //        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite,
        //                                                  countStyle: .file)
        
        let downloadState = DownloadState.from(state: DownloadState.State.IN_PROGRESS, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: progress, media: media, sambaSubtitle: nil)
        
        OfflineUtils.sendNotification(with: downloadState)
    }
    
}


//MARK: - Delegate Download Subtitles
class DownloadSubtitlesDelegate: NSObject, URLSessionDownloadDelegate {
    
    var master: SambaDownloadTracker!
    
    init(master: SambaDownloadTracker) {
        self.master = master;
    }
    
    /// Tells the delegate that the task finished transferring data.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        guard let task = task as? URLSessionDownloadTask, let subtitle = master.captionsForDownloadsMap.removeValue(forKey: task) else { return }
        
        master.sambaSubtitlesDownloading.removeAll(where: {$0.mediaID == subtitle.mediaID})
        OfflineUtils.persistDownloadingSubtitles(master.sambaSubtitlesDownloading)
        master.sambaSubtitlesPaused.removeAll(where: {$0.mediaID == subtitle.mediaID})
        
        
        guard let media = master.sambaMediasDownloaded.first(where: {$0.id == subtitle.mediaID}) else {
            master.deleteSubtitleDownload(subtitle)
            return
        }
        
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
            
            master.deleteSubtitleDownload(subtitle)
            master.deleteMediaDownload(media, isError, false)
            
            downloadState = DownloadState.from(state: isError ? DownloadState.State.FAILED : DownloadState.State.CANCELED, totalDownloadSize: 0, downloadPercentage: 0, media: media, sambaSubtitle: subtitle)
            
        } else {
            downloadState = DownloadState.from(state: DownloadState.State.COMPLETED, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 100, media: media, sambaSubtitle: subtitle)
            
        }
        
        OfflineUtils.sendNotification(with: downloadState)
        
    }
    
    
    
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("a")
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)  {
        
        guard let subtitle = master.captionsForDownloadsMap[downloadTask] else {
            return
        }
        
        guard let media = master.sambaMediasDownloaded.first(where: {$0.id == subtitle.mediaID}) else {
            master.deleteMedia(for: subtitle.mediaID)
            return
        }
        
        
        do {
            
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            
            let extensionFile = URL(string: subtitle.caption.url)?.pathExtension ?? "srt"
            
            let destinationUrl = documentsUrl.appendingPathComponent("\(media.id)_SUBTITLE_\(subtitle.caption.language).\(extensionFile)")
            guard let dataFromURL = try? Data(contentsOf: location) else {
                master.deleteMediaDownload(media, true)
                return
            }
            
            try dataFromURL.write(to: destinationUrl, options: .atomic)
            
            let bookmark = try destinationUrl.bookmarkData()
            
            OfflineUtils.saveSubtitleLocation(with: subtitle, location: bookmark)
            
            if !master.sambaSubtitlesDownloaded.contains(where: {$0.mediaID == subtitle.mediaID}) {
                master.sambaSubtitlesDownloaded.append(subtitle)
            }
            
            OfflineUtils.persistDownloadedSubtitles(master.sambaSubtitlesDownloaded)
            
            let medias = master.sambaMediasDownloaded.filter({$0.id == media.id})
            medias.forEach({$0.isCaptionsOffline = true})
            
            OfflineUtils.persistDownloadedMedias(master.sambaMediasDownloaded)
            
        } catch {
            print("Failed to create bookmark for subtitle: \(location)")
            master.deleteMediaDownload(media, true)
        }
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let subtitle = master.captionsForDownloadsMap[downloadTask],
            !master.sambaSubtitlesPaused.contains(where: {$0.mediaID == subtitle.mediaID}) else { return }
        
        
        guard let media = master.sambaMediasDownloaded.first(where: {$0.id == subtitle.mediaID}) else {
            master.deleteMedia(for: subtitle.mediaID)
            return
        }
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        
        let downloadState = DownloadState.from(state: DownloadState.State.IN_PROGRESS, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: progress, media: media, sambaSubtitle: subtitle)
        
        OfflineUtils.sendNotification(with: downloadState)
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
                sambaMediasPaused.removeAll(where: {$0.id == media.id})
        
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
                    
                    if let subPair = captionsForDownloadsMap.first(where: {$1.mediaID ==  media.id}) {
                        _ = captionsForDownloadsMap.removeValue(forKey: subPair.key)
                    }
            
                    
                    deleteMediaDownload(media, isError, false)

                    downloadState = DownloadState.from(state: isError ? DownloadState.State.FAILED : DownloadState.State.CANCELED, totalDownloadSize: 0, downloadPercentage: 0, media: media)
                    
                    OfflineUtils.sendNotification(with: downloadState)
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
                        
                        OfflineUtils.sendNotification(with: downloadState)
    
                    } else {
                        
                        if let pairSub = captionsForDownloadsMap.first(where: {$1.mediaID == media.id}) {
                            let taskSub = pairSub.key
                            taskSub.resume()
                        } else {
                            downloadState = DownloadState.from(state: DownloadState.State.COMPLETED, totalDownloadSize: media.downloadData?.totalDownloadSizeInMB ?? 0, downloadPercentage: 100, media: media)
                            OfflineUtils.sendNotification(with: downloadState)
                        }
                    }
                }
    
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

extension SambaDownloadTracker: AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        print("e")
        return true
    }
}


