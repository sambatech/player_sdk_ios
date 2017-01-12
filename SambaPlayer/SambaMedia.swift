//
//  SambaMedia.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

/**
Data entity representing a media

If `outputs` field is nil, use `url` field.
*/
@objc public class SambaMedia : NSObject {
	
	/// Media's title
	public var title = ""
	
	/// Current media URL
	public var url: String? {
		didSet {
			guard let urlNonNull = url else { return }

			if urlNonNull.range(of: "\\.m3u8$", options: .regularExpression) != nil {
				deliveryType = "hls"
			}
			else if urlNonNull.range(of: "\\.(mp4|mov)$", options: .regularExpression) != nil {
				deliveryType = "progressive"
			}
			
			if urlNonNull.range(of: "\\.mp3$", options: .regularExpression) != nil {
				isAudio = true
			}
		}
	}
	
	/// DFP tag URL
	public var adUrl: String?
	
	/// List of outputs
	public var outputs: [SambaMediaOutput]?
	
	/// List of captions
	public var captions: [SambaMediaCaption]?
	
	/// Delivery type ( HLS, PROGRESSIVE, OTHER )
	public var deliveryType = "other"
	
	/// Thumb's URL
	public var thumb: UIImage?
	
	/// Indicates if the media is live or not
	public var isLive = false
	
	/// Indicates if the media is audio or not
	public var isAudio = false
	
	/// Media current color theme
	public var theme: UInt = 0x72BE44

	/// Default initializer
	public override init() {}

	/**
	Basic initializer
	
	- parameter url: URL of the media
	- parameter title: Media's title
	- parameter thumb: URL of the thumb
	*/
	public init(_ url: String, title: String?, thumb: UIImage?) {
		self.title = title ?? ""
		self.url = url
		self.thumb = thumb
	}
	
	/**
	Convenience initializer
	
	- parameter url:String URL of the media
	*/
	public convenience init(_ url: String) {
		self.init(url, title: nil, thumb: nil)
	}
	
	/**
	Clone initializer
	
	- parameter media: Another media object to create a clone
	*/
	public init(media: SambaMedia) {
		url = media.url
		title = media.title
		outputs = media.outputs
		captions = media.captions
		adUrl = media.adUrl
		deliveryType = media.deliveryType
		thumb = media.thumb
		isLive = media.isLive
		isAudio = media.isAudio
		theme = media.theme
	}
	
	/// Description of the media (returns media's title when empty)
	public override var description: String { return title }
}

/**
Output entity

- url: Media URL
- label: Output label
- isDefault: Is it the default output?
*/
@objc public class SambaMediaOutput : NSObject {
	public let url: String
	public let label: String
	public let isDefault: Bool
	
	public init(url: String, label: String, isDefault: Bool) {
		self.url = url
		self.label = label
		self.isDefault = isDefault
	}
}

/**
Caption entity

- url: Caption URL
- label: Caption label
- language: Caption language identifier
- cc: Is it CC (Closed Caption)?
- isDefault: Is it the default caption?
*/
@objc public class SambaMediaCaption : NSObject {
	public let url: String
	public let label: String
	public let language: String
	public let cc: Bool
	public let isDefault: Bool
	
	public init(url: String, label: String, language: String, cc: Bool, isDefault: Bool) {
		self.url = url
		self.label = label
		self.language = language
		self.cc = cc
		self.isDefault = isDefault
	}
}

/**
* Internal extension of the media entity for player/plugins config purposes.
 */
@objc public class SambaMediaConfig : SambaMedia {

	/// The ID of the media
	public var id = ""
	/// The project hash the media belongs to
	public var projectHash = ""
	/// The project ID the media belongs to
	public var projectId = 0
	/// The category ID the media belongs to
	public var categoryId = 0
	/// The STTM session ID
	public var sessionId = Helpers.getSessionId()
	/// The STTM URL
	public var sttmUrl = "http://sttm.sambatech.com.br/collector/__sttm.gif"
	/// The STTM key
	public var sttmKey = "ae810ebc7f0654c4fadc50935adcf5ec"
	/// The DRM validation request
	public var drmRequest: DrmRequest?
	/// Whether to check or not if the device has been jailbroken to block media playback
	public var blockIfRooted = false
	
	/**
	Default initializer
	*/
	public override init() {
		super.init()
	}
	
	/**
	Clone initializer
	
	- parameter media: The ID of the media
	*/
	public override init(media: SambaMedia) {
		super.init(media: media)
		
		if let m = media as? SambaMediaConfig {
			id = m.id
			projectHash = m.projectHash
			projectId = m.projectId
			categoryId = m.categoryId
			sessionId = m.sessionId
			sttmUrl = m.sttmUrl
			sttmKey = m.sttmKey
			drmRequest = m.drmRequest
			blockIfRooted = m.blockIfRooted
		}
	}
}

/// Represents a DRM validation request
@objc public class DrmRequest : NSObject {
	
	/// Application Certificate URL
	public var acUrl: String {
		get { return "\(_acUrl)?\(acUrlParamsStr)" }
		set { _acUrl = newValue }
	}
	
	/// License URL
	public var licenseUrl: String {
		get { return "\(_licenseUrl)?\(licenseUrlParamsStr)" }
		set { _licenseUrl = newValue }
	}
	
	/// License URL parameters
	public var licenseUrlParamsStr: String {
		var p = [String]()
		
		for (k,v) in _licenseUrlParams {
			p.append("\(k)=\(v)")
		}
		
		return p.joined(separator: "&")
	}
	
	/// Application Certificate URL parameters
	public var acUrlParamsStr: String {
		var p = [String]()
		
		for (k,v) in _acUrlParams {
			p.append("\(k)=\(v)")
		}
		
		return p.joined(separator: "&")
	}
	
	private var _licenseUrlParams = [String: String]()
	private var _acUrlParams = [String: String]()
	private var _acUrl: String
	private var _licenseUrl: String
	
	/**
	Default initializer
	
	- parameter acUrl: Application Certificate URL
	- parameter licenseUrl: License URL
	*/
	public init(_ acUrl: String, _ licenseUrl: String) {
		self._acUrl = acUrl
		self._licenseUrl = licenseUrl
		
		super.init()
	}
	
	/**
	Adds a license URL parameter for the request
	*/
	public func addLicenseParam(key: String, value: String) {
		_licenseUrlParams[key] = value
	}
	
	/**
	Adds a Application Certificate URL parameter for the request
	*/
	public func addACParam(key: String, value: String) {
		_acUrlParams[key] = value
	}
	
	/**
	Retrieves a license URL parameter by key
	
	- parameter key: The key related to the parameter
	*/
	public func getLicenseParam(key: String) -> String? {
		return _licenseUrlParams[key]
	}
	
	/**
	Retrieves a Application Certificate URL parameter by key
	
	- parameter key: The key related to the parameter
	*/
	public func getACParam(key: String) -> String? {
		return _acUrlParams[key]
	}
}
