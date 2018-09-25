//
//  SambaCast.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 18/09/2018.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation
import GoogleCast

public class SambaCast: NSObject {
    
    public static var sharedInstance = SambaCast()
    
    fileprivate var delegates: [SambaCastDelegate] = []
    
    private var channel: SambaCastChannel?
    
    private var sambaCastRequest: SambaCastRequest = SambaCastRequest()
    
    public var enableSDKLogging: Bool = false
    
    public var isCastDialogShowing: Bool = false
    
    private weak var buttonForIntrucions: SambaCastButton?
    
    private override init() {}
    
    
    //MARK: - Public Methods
    
    public func subscribe(delegate: SambaCastDelegate)  {
        let index = delegates.index(where: {$0 === delegate})
        
        guard index == nil else {
            return
        }
        
        delegates.append(delegate)
        
    }
    
    public func unSubscribe(delegate: SambaCastDelegate)  {
        
        guard let index = delegates.index(where: {$0 === delegate}) else {
            return
        }
        
        delegates.remove(at: index)
    }
    
    public func config() {
        let criteria = GCKDiscoveryCriteria(applicationID: Helpers.settings["cast_application_id_prod"]!)
        let options = GCKCastOptions(discoveryCriteria: criteria)
        options.stopReceiverApplicationWhenEndingSession = true
        GCKCastContext.setSharedInstanceWith(options)
        setupCastLogging()
        GCKCastContext.sharedInstance().sessionManager.add(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.castDialogWillShow),
                                               name: NSNotification.Name.gckuiCastDialogWillShow,
                                               object: GCKCastContext.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(self.castDialogDidHide),
                                               name: NSNotification.Name.gckuiCastDialogDidHide,
                                               object: GCKCastContext.sharedInstance())
    }
    
    public func isCasting() -> Bool {
        return GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession()
    }
    
    public func presentCastInstruction(with button: SambaCastButton) {
        self.buttonForIntrucions = button
        NotificationCenter.default.addObserver(self, selector: #selector(self.castDeviceDidChange),
                                               name: NSNotification.Name.gckCastStateDidChange,
                                               object: GCKCastContext.sharedInstance())
    }
    
    public func stopCasting() {
        GCKCastContext.sharedInstance().sessionManager.endSessionAndStopCasting(true)
    }
    
    public func loadMedia(with media: SambaMedia, currentTime: CLong = 0, captionTheme: String? = nil, completion: @escaping (SambaCastCompletionType, Error?) -> Void) {
        guard hasCastSession() else { return }
        let castModel = CastModel.castModelFrom(media: media, currentTime: currentTime, captionTheme: captionTheme)
        guard let jsonCastModel = castModel.toStringJson() else { return }
        
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString(media.title, forKey: kGCKMetadataKeyTitle)
    
        
        if getPersistedCurrentMedia() != castModel.m {
            let mediaInfo = GCKMediaInformation(contentID: jsonCastModel, streamType: .buffered,
                                                contentType: "video/mp4", metadata: metadata,
                                                streamDuration: TimeInterval(media.duration),
                                                mediaTracks: nil,
                                                textTrackStyle: nil, customData: nil)
            let builder = GCKMediaQueueItemBuilder()
            builder.mediaInformation = mediaInfo
            builder.autoplay = false
            let item = builder.build()
            let request = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient?.queueLoad([item], start: 0, playPosition: 0,
                                                                                                                          repeatMode: .off, customData: nil)
            sambaCastRequest.set { [weak self] error in
                guard let strongSelf = self else { return }
                guard error == nil else {
                    completion(.error, error)
                    return
                }
                strongSelf.persistCurrentMedia(id: castModel.m!)
                completion(.loaded, nil)
            }
            request?.delegate = sambaCastRequest
        } else {
            completion(.resumed, nil)
        }
        
    }
    
    
    //MARK: - Internal Methods
    
    func playCast() {
        let message = "{\"type\": \"play\"}"
        sendRequest(with: message);
    }
    
    func pauseCast() {
        let message = "{\"type\": \"pause\"}"
        sendRequest(with: message);
    }
    
    func seek(to position: CLong) {
        let message = "{\"type\": \"seek\", \"data\": \(position/1000) }"
        sendRequest(with: message);
    }
    
    func changeSubtitle(to language: String?) {
        let data: String!
        
        if let mLanguage = language {
            data = "{\"lang\": \"\(mLanguage)\"}"
        } else {
            data = "{\"lang\": \"none\"}"
        }
        
        let message = "{\"type\": \"changeSubtitle\", \"data\": \(data) }"
            
        sendRequest(with: message)
    }
    
    func registerDeviceForProgress(enable: Bool) {
        let message = "{\"type\": \"registerForProgressUpdate\", \"data\": \(enable) }"
        sendRequest(with: message)
    }
    
    //MARK: - Private Methods
    
    private func setupCastLogging() {
        let logFilter = GCKLoggerFilter()
        let classesToLog = ["GCKDeviceScanner", "GCKDeviceProvider", "GCKDiscoveryManager", "GCKCastChannel",
                            "GCKMediaControlChannel", "GCKUICastButton", "GCKUIMediaController", "NSMutableDictionary"]
        logFilter.setLoggingLevel(.verbose, forClasses: classesToLog)
        GCKLogger.sharedInstance().filter = logFilter
        GCKLogger.sharedInstance().delegate = self
    }
    
    fileprivate func onCastSessionConnected() {
        enableChannel()
        enableChannelForReceiveMessages()
        delegates.forEach({$0.onCastConnected?()})
    }
    
    fileprivate func onCastSessionDisconnected() {
        disableChannel()
        clearCaches()
        delegates.forEach({$0.onCastDisconnected?()})
    }
    
    private func hasCastSession() -> Bool {
        guard let currentCastSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession  else { return false }
        guard currentCastSession.connectionState == .connected else { return false }
        return true
    }
    
    private func sendRequest(with message: String) {
        if hasCastSession() {
            channel?.sendTextMessage(message, error: nil)
        }
    }
    
    private func enableChannel() {
        if channel == nil && hasCastSession() {
            channel = SambaCastChannel(namespace: Helpers.settings["cast_namespace_prod"]!)
            GCKCastContext.sharedInstance().sessionManager.currentCastSession?.add(channel!)
        }
    }
    
    private func disableChannel() {
        if channel != nil {
            GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remove(channel!)
            channel?.delegate = nil
            channel = nil
        }
    }
    
    //MARK: - Helpers
    
    private func enableChannelForReceiveMessages() {
        registerDeviceForProgress(enable: true)
        channel?.delegate = self
    }
    
    private func persistCurrentMedia(id: String) {
        UserDefaults.standard.set(id, forKey: "media_id")
    }
    
    private func getPersistedCurrentMedia() -> String? {
        return UserDefaults.standard.string(forKey: "media_id")
    }
    
    func clearCaches() {
        UserDefaults.standard.removeObject(forKey: "media_id")
    }
    
    //MARK: - Observers
    
    @objc private func castDeviceDidChange() {
        if let mButton = self.buttonForIntrucions, GCKCastContext.sharedInstance().castState != .noDevicesAvailable {
            GCKCastContext.sharedInstance().presentCastInstructionsViewControllerOnce(with: mButton)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.gckCastStateDidChange, object: GCKCastContext.sharedInstance())
            self.buttonForIntrucions = nil
        }
    }
    
    @objc private func castDialogWillShow() {
        isCastDialogShowing = true
    }
    
    @objc private func castDialogDidHide() {
        isCastDialogShowing = false
    }
}

//MARK: - Extensions

extension SambaCast: GCKLoggerDelegate {
    public func logMessage(_ message: String, fromFunction function: String) {
        if enableSDKLogging {
            print("\(function)  \(message)")
        }
    }
    
}

extension SambaCast: GCKSessionManagerListener {
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        print("sessionManager didStartSession \(session)")
        onCastSessionConnected()
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        print("SessionManager didResumeSession \(session)")
        onCastSessionConnected()
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        print("Session ended with error: \(String(describing: error))")
        onCastSessionDisconnected()
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStartSessionWithError error: Error?) {
        if let error = error {
             print("Session fail to start with error: \(String(describing: error))")
        }
        onCastSessionDisconnected()
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager,
                        didFailToResumeSession session: GCKSession, withError error: Error?) {
        print("Session fail to resume with error: \(String(describing: error))")
        onCastSessionDisconnected()
    }
}


extension SambaCast: SambaCastChannelDelegate {
    
    func didReceiveMessage(message: String) {
        guard let jsonDicitonary = Helpers.convertToDictionary(text: message) else { return }
        
        if let position = jsonDicitonary["progress"] as? Double, let duration = jsonDicitonary["duration"] as? Double {
            delegates.forEach({ $0.onCastProgress?(position: CLong(position * 1000), duration: CLong(duration * 1000))})
        } else if let type = jsonDicitonary["type"] as? String {
            if type.lowercased().elementsEqual("finish") {
                delegates.forEach({ $0.onCastFinish?() })
            }
        }
    }
    
}

//MARK: - Protocols

@objc public protocol SambaCastDelegate: class {
    
    @objc optional func onCastConnected()
    
    @objc optional func onCastDisconnected()
    
    @objc optional func onCastPlay()
    
    @objc optional func onCastPause()
    
    @objc optional func onCastProgress(position: CLong, duration: CLong)
    
    @objc optional func onCastFinish()
}


//MARK: - Enums

public enum SambaCastCompletionType {
    case loaded
    case resumed
    case error
}



