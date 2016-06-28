//
//  SambaMediaRequest.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/9/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation

@objc public class SambaMediaRequest : NSObject {
	
	public var projectHash: String
	public var mediaId: String?
	public var streamName: String?
	public var streamUrls: [String]?
	
	public init(projectHash: String, mediaId: String?, streamName: String?, streamUrls: [String]?) {
		self.projectHash = projectHash
		self.mediaId = mediaId
		self.streamName = streamName
		self.streamUrls = streamUrls
	}
	
	public convenience init(projectHash: String, streamUrls: [String]) {
		self.init(projectHash: projectHash, mediaId: nil, streamName: nil, streamUrls: streamUrls)
	}
	
	public convenience init(projectHash: String, streamUrl: String) {
		self.init(projectHash: projectHash, mediaId: nil, streamName: nil, streamUrls: [streamUrl])
	}
	
	public convenience init(projectHash: String, streamName: String) {
		self.init(projectHash: projectHash, mediaId: nil, streamName: streamName, streamUrls: nil)
	}
	
	public convenience init(projectHash: String, mediaId: String) {
		self.init(projectHash: projectHash, mediaId: mediaId, streamName: nil, streamUrls: nil)
	}
}
