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
	
	public var apiProtocol = SambaProtocol.https
	
	/// The project hash the media belongs to
	public var projectHash: String
	
	/// ID of the media
	public var mediaId: String?
	
	/// The live channel ID
	public var liveChannelId: String?
	
	/// Name of the media stream for live content
	public var streamName: String?
	
	/// URL for live content
	public var streamUrl: String?
	
	/// URL list for backup/fallback purposes
	public var backupUrls = [String]()
	
	/// Whether the media is both live and audio
	public var isLiveAudio = false
	
	/// The environment of the Samba Player API to request for
	public var environment = SambaEnvironment.prod
	
	/**
	Live initializer (by URL)
	
	- parameter projectHash: The project hash the media belongs to
	- parameter streamUrl: URL for live content
	- parameter backupUrls: Optional URL list for backup/fallback purposes
	*/
	@objc public init(projectHash: String, streamUrl: String, backupUrls: [String]? = nil) {
		self.projectHash = projectHash
		self.streamUrl = streamUrl
		
		if let backupUrls = backupUrls { self.backupUrls = backupUrls }
	}
	
	/**
	Convenience constructor, please refer to its original version.
	*/
    public convenience init(projectHash: String, streamUrl: String, backupUrls: String...) {
		self.init(projectHash: projectHash, streamUrl: streamUrl, backupUrls: backupUrls)
	}
	
	/**
	Convenience constructor, please refer to its original version.
	*/
	@objc public convenience init(projectHash: String, streamUrl: String) {
		self.init(projectHash: projectHash, streamUrl: streamUrl, backupUrls: [String]())
	}
	
	/**
	Live initializer (by URL + audio option)
	
	- parameter projectHash: The project hash the media belongs to
	- parameter isLiveAudio: Whether the media is both live and audio
	- parameter streamUrl: URL for live content
	- parameter backupUrls: Optional URL list for backup/fallback purposes
	*/
	@objc public init(projectHash: String, isLiveAudio: Bool, streamUrl: String, backupUrls: [String]? = nil) {
		self.projectHash = projectHash
		self.isLiveAudio = isLiveAudio
		self.streamUrl = streamUrl
		
		if let backupUrls = backupUrls { self.backupUrls = backupUrls }
	}
	
	/**
	Convenience constructor, please refer to its original version.
	*/
    public convenience init(projectHash: String, isLiveAudio: Bool, streamUrl: String, backupUrls: String...) {
		self.init(projectHash: projectHash, isLiveAudio: isLiveAudio, streamUrl: streamUrl, backupUrls: backupUrls)
	}
	
	/**
	Live initializer (by stream name)
	
	- parameter projectHash: The project hash the media belongs to
	- parameter streamName: Name of the media stream for live content
	*/
	@objc public init(projectHash: String, streamName: String) {
		self.projectHash = projectHash
		self.streamName = streamName
	}
	
	/**
	VoD initializer
	
	- parameter projectHash: The project hash the media belongs to
	- parameter mediaId: The ID of the media
	*/
	@objc public init(projectHash: String, mediaId: String) {
		self.projectHash = projectHash
		self.mediaId = mediaId
	}
	
	/**
	Live initializer
	
	- parameter projectHash: The project hash the media belongs to
	- parameter liveChannelId: The ID of the live channel
	*/
	@objc public init(projectHash: String, liveChannelId: String) {
		self.projectHash = projectHash
		self.liveChannelId = liveChannelId
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

/// Samba Player API protocol list
public enum SambaProtocol: String {
	/// Insecure
	case http
	
	///Secure
	case https
}
