//
//  SambaMediaRequest.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation

/// Data entity that represents a media request to the Samba Player API
@objc public class SambaMediaRequest : NSObject {
	
	/// The project hash the media belongs to
	public var projectHash: String
	
	/// ID of the media
	public var mediaId: String?
	
	/// Name of the media stream for live content
	public var streamName: String?
	
	/// URL list of streams when live content being the first the main URL and the rest for backup purpose
	public var streamUrls: [String]?
	
	/// Whether the media is both live and audio
	public var isLiveAudio = false
	
	/// The environment of the Samba Player API to request for
	public var environment: SambaEnvironment = .prod
	
	/**
	Default initializer
	
	- parameter projectHash: The project hash the media belongs to
	- parameter mediaId: ID of the media
	- parameter streamName: Name of the media stream for live content
	- parameter streamUrls: URL list of streams when live content being the first the main URL and the rest for backup purpose
	- parameter isAudio: Whether the media is both live and audio
	*/
	public init(projectHash: String, mediaId: String?, streamName: String?, streamUrls: [String]?, isLiveAudio: Bool = false) {
		self.projectHash = projectHash
		self.mediaId = mediaId
		self.streamName = streamName
		self.streamUrls = streamUrls
		self.isLiveAudio = isLiveAudio
	}
	
	/**
	Convenience initializer
	
	- parameter projectHash: The project hash the media belongs to
	- parameter streamUrls: URL list of streams when live content being the first the main URL and the rest for backup purpose
	*/
	public convenience init(projectHash: String, streamUrls: [String]) {
		self.init(projectHash: projectHash, mediaId: nil, streamName: nil, streamUrls: streamUrls)
	}
	
	/**
	Convenience initializer
	
	- parameter projectHash: The project hash the media belongs to
	- parameter streamUrl: URL of stream when live content
	- parameter isLiveAudio: Whether the media is both live and audio
	*/
	public convenience init(projectHash: String, streamUrl: String, isLiveAudio: Bool = false) {
		self.init(projectHash: projectHash, mediaId: nil, streamName: nil, streamUrls: [streamUrl], isLiveAudio: isLiveAudio)
	}
	
	/**
	Convenience initializer
	
	- parameter projectHash: The project hash the media belongs to
	- parameter streamName: Name of the media stream for live content
	*/
	public convenience init(projectHash: String, streamName: String) {
		self.init(projectHash: projectHash, mediaId: nil, streamName: streamName, streamUrls: nil)
	}
	
	/**
	Convenience initializer
	
	- parameter projectHash: The project hash the media belongs to
	- parameter mediaId: ID of the media
	*/
	public convenience init(projectHash: String, mediaId: String) {
		self.init(projectHash: projectHash, mediaId: mediaId, streamName: nil, streamUrls: nil)
	}
}

/// Samba Player API environment list
@objc public enum SambaEnvironment: Int {
	/// Production environment
	case prod
	/// Staging environment
	case staging
	/// Development/Testing environment
	case test
	/// Local environment
	case local
}
