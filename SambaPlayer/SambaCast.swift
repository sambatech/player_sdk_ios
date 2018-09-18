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
    
    private var delegates: [SambaCastDelegate] = []
    
    public var enableSDKLogging: Bool = false
    
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
        delegates.forEach({$0.onConnected?()})
    }
    
    fileprivate func onCastSessionDisconnected() {
        delegates.forEach({$0.onDisconnected?()})
    }
    
    //MARK: - Observers
    
    @objc private func castDeviceDidChange() {
        if let mButton = self.buttonForIntrucions, GCKCastContext.sharedInstance().castState != .noDevicesAvailable {
            GCKCastContext.sharedInstance().presentCastInstructionsViewControllerOnce(with: mButton)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.gckCastStateDidChange, object: GCKCastContext.sharedInstance())
            self.buttonForIntrucions = nil
        }
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

extension SambaCast: GCKRequestDelegate {
    
    public func requestDidComplete(_ request: GCKRequest) {
        print("request \(Int(request.requestID)) completed")
    }
    
    public func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        print("request \(Int(request.requestID)) failed with error \(error)")
    }
    
}

//MARK: - Protocols

@objc public protocol SambaCastDelegate: class {
    
    @objc optional func onConnected()
    
    @objc optional func onDisconnected()

}
