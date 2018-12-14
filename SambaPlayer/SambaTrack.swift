//
//  SambaTrack.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 29/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

public struct SambaTrack {
    public var title: String
    public var sizeInMb: Double
    public var width: Int
    public var height: Int
    public var isProgressive: Bool
    var output: SambaPlayer.Output
}

public struct SambaSubtitle: Codable {
    public var title: String
    
    var mediaID: String
    var caption: SambaMediaCaption
}
