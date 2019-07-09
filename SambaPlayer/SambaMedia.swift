//
//  SambaMedia.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

/**
Data entity representing a media

If `outputs` field is nil, `url` field will be used instead.
*/
@objc public class SambaMedia : NSObject {
	
	/// Media's title
	public var title = ""
	
	/// Current media URL
	public var url: String? {
		didSet {
			guard var urlNonNull = url else { return }

			// tries to fallback from HDS
			urlNonNull = urlNonNull.replacingOccurrences(of: "[\\w]+\\.f4m$", with: "playlist.m3u8", options: .regularExpression)
			url = urlNonNull
			
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
	
	/// URL list for backup/fallback purposes
	public var backupUrls = [String]()
	
	/// DFP tag URL
	public var adUrl: String?
	
	/// DFP settings
	public var adsSettings = GMFAdsSettings()
	
	/// List of outputs
	public var outputs: [SambaMediaOutput]?
	
	/// List of captions
	public var captions: [SambaMediaCaption]?
	
	/// Captions configuration
	public var captionsConfig = SambaMediaCaptionsConfig()
	
	/// Delivery type ( HLS, PROGRESSIVE, OTHER )
	public var deliveryType = "other"
	
	/// Thumb's URL
	public var thumb: UIImage?
    
    public var thumbURL: String?
    
    public var externalThumbURL: String?

	
	/// Indicates if the media is live or not
	public var isLive = false
	
	/// Indicates if the media is audio or not
	public var isAudio = false
    
    public var isOffline = false
    public var isCaptionsOffline = false
	
	/// Indicates if the media has DVR support
	public var isDvr = false
	
	/// Media current color theme
	public var theme: UInt = 0x72BE44
    
    public var themeColorHex: String = "#72BE44"
    
    public var duration: Float = 0
    
    public var offlineUrl: String?
    
    public var offlinePath: String?
    
    public var downloadData: DownloadData?
	
	/// Description of the media (returns media's title when empty)
	public override var description: String { return title }
	
	/// Default initializer
	public override init() {
		super.init()
	}
	
	/**
	Basic initializer
	
	- parameter url: URL of the media
	- parameter title: Media's title
	- parameter thumb: URL of the thumb
	*/
	@objc public init(_ url: String, title: String? = nil, thumb: UIImage? = nil) {
		self.title = title ?? ""
		self.url = url
		self.thumb = thumb
		
		super.init()
	}
	
	/**
	Clone initializer
	
	- parameter media: Another media object to create a clone
	*/
	@objc public init(media: SambaMedia) {
		url = media.url
		backupUrls = media.backupUrls
		title = media.title
		outputs = media.outputs
		captions = media.captions
		adUrl = media.adUrl
		adsSettings = media.adsSettings
		deliveryType = media.deliveryType
		thumb = media.thumb
		isLive = media.isLive
		isAudio = media.isAudio
		isDvr = media.isDvr
		theme = media.theme
        thumbURL = media.thumbURL
        externalThumbURL = media.externalThumbURL
		offlineUrl = media.offlineUrl
        offlinePath = media.offlinePath
        downloadData = media.downloadData
		super.init()
	}
}

/**
Output entity
*/
@objc public class SambaMediaOutput : NSObject, Codable {
	/// Media URL
	public let url: String
	/// Output label
	public let label: String
	/// Is it the default output?
	public let isDefault: Bool
	
	@objc public init(url: String, label: String, isDefault: Bool) {
		self.url = url
		self.label = label
		self.isDefault = isDefault
	}
}

/**
Caption entity
*/
@objc public class SambaMediaCaption : NSObject, Codable {
	/// Caption URL
	public let url: String
	/// Caption label
	public let label: String
	/// Caption language identifier (e.g. pt-br)
	public let language: String
	/// Is it CC (Closed Caption)?
	public let cc: Bool
	/// Is it the default caption?
	public let isDefault: Bool
	
	@objc public init(url: String, label: String, language: String, cc: Bool, isDefault: Bool) {
		self.url = url
		self.label = label
		self.language = language
		self.cc = cc
		self.isDefault = isDefault
	}
}

/**
Configuration for captions
*/
@objc public class SambaMediaCaptionsConfig : NSObject, Codable {
	/// Captions color
	public let color: UInt
	/// Captions size
	public let size: Int
	/// Initial caption by identifier (e.g. pt-br)
	public let language: String?
	
	@objc public init(color: UInt = 0xFFCC00, size: Int = 24, language: String? = nil) {
		self.color = color
		self.size = size
		self.language = language
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
    public var clientId = 0
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
	/// Number of times the player can try to resume the media on failure
	public var retriesTotal = 3
	
    public var bitrate: CLong?
    
	/**
	Default initializer
	*/
	public required override init() {
		super.init()
	}
	
	/**
	Clone initializer
	
	- parameter media: The ID of the media
	*/
	@objc public override init(media: SambaMedia) {
		super.init(media: media)
		
		if let m = media as? SambaMediaConfig {
			id = m.id
			projectHash = m.projectHash
            clientId = m.clientId
			projectId = m.projectId
			categoryId = m.categoryId
			sessionId = m.sessionId
			sttmUrl = m.sttmUrl
			sttmKey = m.sttmKey
			drmRequest = m.drmRequest
			blockIfRooted = m.blockIfRooted
            bitrate = m.bitrate
		}
	}
}

/// Represents a DRM validation request
@objc public class DrmRequest : NSObject, Codable {
	
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
        
        if let mToken = token, !mToken.isEmpty {
            p.append("ls_session=\(mToken)")
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
    
    public var token: String?
	
	private var _licenseUrlParams = [String: String]()
	private var _acUrlParams = [String: String]()
	private var _acUrl: String
	private var _licenseUrl: String
    
    var applicationID: String?
    var provider: String?
	
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
	public func addLicenseParam(key: String, value: String?) {
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
