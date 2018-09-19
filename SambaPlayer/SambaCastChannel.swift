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
}

protocol SambaCastChannelDelegate: class {
    func didReceiveMessage(message: String)
}
