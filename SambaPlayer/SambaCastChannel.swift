//
//  SambaCastChannel.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 19/09/2018.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation
import GoogleCast

class SambaCastChannel: GCKCastChannel {
    weak var delegate: SambaCastChannelDelegate?
    
    override func didReceiveTextMessage(_ message: String) {
        delegate?.didReceiveMessage(message: message)
    }
}

protocol SambaCastChannelDelegate: class {
    func didReceiveMessage(message: String)
}


class SambaCastRequest: NSObject, GCKRequestDelegate {
    
    private var callback: ((Error?) -> Void)?
    
    func set(callback: @escaping (Error?) -> Void) {
        self.callback = callback
    }

    public func requestDidComplete(_ request: GCKRequest) {
        callback?(nil)
    }
    
    public func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        callback?(error)
    }
}
