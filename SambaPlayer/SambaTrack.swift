//
//  SambaTrack.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 29/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

public struct SambaTrack {
    var title: String
    var sizeInMb: Double
    var width: Int
    var height: Int
    var isAudio: Bool
}

public struct SambaSubtitle {
    var title: String
    var caption: SambaMediaCaption
}
