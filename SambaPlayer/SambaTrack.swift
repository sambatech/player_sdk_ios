//
//  SambaTrack.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 29/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation

public class SambaTrack: NSObject {
    public var title: String
    public var sizeInMb: Double
    public var width: Int
    public var height: Int
    public var isProgressive: Bool
    var output: SambaPlayer.Output
    
    init(title: String, sizeInMb: Double, width: Int, height: Int, isProgressive: Bool, output: SambaPlayer.Output) {
        self.title = title
        self.sizeInMb = sizeInMb
        self.width = width
        self.height = height
        self.isProgressive = isProgressive
        self.output = output
    }
}

public class SambaSubtitle: NSObject, Codable {
    public var title: String
    
    var mediaID: String
    var caption: SambaMediaCaption
    
    init(title: String, mediaID: String, caption: SambaMediaCaption) {
        self.title = title
        self.mediaID = mediaID
        self.caption = caption
    }
}
