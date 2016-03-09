//
//  SambaMediaRequest.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/9/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation

public class SambaMediaRequest {
	
	public var projectHash: String
	public var mediaId: String?
	
	init(projectHash: String, mediaId: String?) {
		self.projectHash = projectHash
		self.mediaId = mediaId
	}
}