//
//  SambaMediaRequest.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation

@objc public class SambaMediaRequest : NSObject {
	
	///Project Hash of the media
	public var projectHash: String
	
	///ID of the media
	public var mediaId: String?
	
	///If it´s live, streamName of the media
	public var streamName: String?
	
	//If it´s live you can put a list of StreamURL
	public var streamUrls: [String]?
	
	//If it´s live and audio
	public var isLiveAudio: Bool?
	
	
	/**
	Default initializer
	
	- Parameters:
		- projectHash:String Project Hash of the media
		- mediaId:String ID of the media
		- streamName:String streamName of the media live
		- streamUrls:[String] List of streamURLs
	*/
	public init(projectHash: String, mediaId: String?, streamName: String?, streamUrls: [String]?) {
		self.projectHash = projectHash
		self.mediaId = mediaId
		self.streamName = streamName
		self.streamUrls = streamUrls
	}
	
	/**
	Second initializer
	
	- Parameters:
	- projectHash:String Project Hash of the media
	- mediaId:String ID of the media
	- streamName:String streamName of the media live
	- streamUrls:[String] List of streamURLs
	- isAudio: Bool Is Audio
	*/
	public init(projectHash: String, mediaId: String?, streamName: String?, streamUrls: [String]?, isLiveAudio: Bool?) {
		self.projectHash = projectHash
		self.mediaId = mediaId
		self.streamName = streamName
		self.streamUrls = streamUrls
		self.isLiveAudio = isLiveAudio
	}
	
	/**
	Convenience initializer
	
	- Parameters:
		- projectHash:String Project Hash of the media
		- streamUrls:[String] List of streamURLs
	*/
	public convenience init(projectHash: String, streamUrls: [String]) {
		self.init(projectHash: projectHash, mediaId: nil, streamName: nil, streamUrls: streamUrls)
	}
	
	/**
	Convenience initializer
	
	- Parameters:
		- projectHash:String Project Hash of the media
		- streamName:String streamName of the media live
	*/
	public convenience init(projectHash: String, streamUrl: String, isLiveAudio: Bool?) {
		self.init(projectHash: projectHash, mediaId: nil, streamName: nil, streamUrls: [streamUrl], isLiveAudio: isLiveAudio)
	}
	
	/**
	Convenience initializer
	
	- Parameters:
		- projectHash:String Project Hash of the media
		- streamName:String streamName of the media live
	*/
	public convenience init(projectHash: String, streamName: String) {
		self.init(projectHash: projectHash, mediaId: nil, streamName: streamName, streamUrls: nil)
	}
	
	/**
	Convenience initializer
	
	- Parameters:
		- projectHash:String Project Hash of the media
		- mediaId:String ID of the media
	*/
	public convenience init(projectHash: String, mediaId: String) {
		self.init(projectHash: projectHash, mediaId: mediaId, streamName: nil, streamUrls: nil)
	}
}
