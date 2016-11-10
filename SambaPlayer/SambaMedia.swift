//
//  SambaMedia.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

/**
 * Data entity representing a media.
 *
 * If `outputs` field is nil, use `url` field.
 */
@objc public class SambaMedia : NSObject {
	
	/**
	Output structure
	
	- url:String Media URL
	- label:String Output label
	- isDefault:Bool Is the default output of the project
	*/
	public struct Output {
		let url: String, label: String, isDefault: Bool
	}
	
	///Media´s title
	public var title = ""
	
	///Current media URL
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
	
	///DFP tag URL
	public var adUrl: String?
	
	///List of the outputs
	public var outputs: [SambaMedia.Output]?
	
	///Delivery type ( HLS, PROGRESSIVE, OTHER )
	public var deliveryType = "other"
	
	///Thumb´s URL
	public var thumb: UIImage?
	
	///Indicate if the media is live or not
	public var isLive = false
	
	///Indicate if the media is audio or not
	public var isAudio = false
	
	///Media current color theme
	public var theme: UInt = 0x72BE44

	///Default initializer
	public override init() {}

	/**
	Media initializer
	
	- Parameters:
		- url:String URL of the media
		- title:String Media´s title
		- thumb:String URL of the thumb
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
	Convenience initializer
	
	- parameter media:SambaMedia A SambaMedia object to clone from
	*/
	public init(media: SambaMedia) {
		url = media.url
		title = media.title
		outputs = media.outputs
		adUrl = media.adUrl
		deliveryType = media.deliveryType
		thumb = media.thumb
		isLive = media.isLive
		isAudio = media.isAudio
		theme = media.theme
	}
	
	///Description of the media ( if empty returns the media´s title
	public override var description: String { return title }
}

/**
 * Internal extension of the media entity for player/plugins config purposes.
 */
@objc public class SambaMediaConfig : SambaMedia {

	public var id = ""
	public var projectHash = ""
	public var projectId = 0
	public var categoryId = 0
	public var sessionId = Helpers.getSessionId()
	public var sttmUrl = "http://sttm.sambatech.com.br/collector/__sttm.gif"
	public var sttmKey = "ae810ebc7f0654c4fadc50935adcf5ec"
	public var drmRequest: DrmRequest?
	public var blockIfRooted = false
	
	public override init() {
		super.init()
	}
	
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

@objc public class DrmRequest : NSObject {
	
	public var acUrl: String {
		get { return "\(_acUrl)?\(acUrlParamsStr)" }
		set { _acUrl = newValue }
	}
	
	public var licenseUrl: String {
		get { return "\(_licenseUrl)?\(licenseUrlParamsStr)" }
		set { _licenseUrl = newValue }
	}
	
	public var licenseUrlParamsStr: String {
		var p = [String]()
		
		for (k,v) in licenseUrlParams {
			p.append("\(k)=\(v)")
		}
		
		return p.joined(separator: "&")
	}
	
	public var acUrlParamsStr: String {
		var p = [String]()
		
		for (k,v) in acUrlParams {
			p.append("\(k)=\(v)")
		}
		
		return p.joined(separator: "&")
	}
	
	public var licenseUrlParams = [String: String]()
	public var acUrlParams = [String: String]()
	
	private var _acUrl: String
	private var _licenseUrl: String
	
	public init(_ acUrl: String, _ licenseUrl: String) {
		self._acUrl = acUrl
		self._licenseUrl = licenseUrl
		
		super.init()
	}
}
