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

			if urlNonNull.rangeOfString("\\.m3u8$", options: .RegularExpressionSearch) != nil {
				deliveryType = "hls"
			}
			else if urlNonNull.rangeOfString("\\.(mp4|mov)$", options: .RegularExpressionSearch) != nil {
				deliveryType = "progressive"
			}
			
			if urlNonNull.rangeOfString("\\.mp3$", options: .RegularExpressionSearch) != nil {
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
	public var thumb: String?
	
	///Indicate if the media is live or not
	public var isLive = false
	
	///Indicate if the media is audio or not
	public var isAudio = false
	
	///Media current color theme
	public var theme: UInt = 0x72BE44

	///Default initializer
	public override init() {}
	
	/**
	Convenience initializer
	
	- parameter url:String URL of the media
	*/
	public convenience init(_ url:String) {
		self.init(url, title: nil, thumb: nil)
	}

	/**
	Media initializer
	
	- Parameters:
		- url:String URL of the media
		- title:String Media´s title
		- thumb:String URL of the thumb
	*/
	public init(_ url:String, title:String?, thumb:String?) {
		self.title = title ?? ""
		self.url = url
		self.thumb = thumb
	}
	
	///Description of the media ( if empty returns the media´s title
	public override var description: String { return title }
}

/**
 * Internal extension of the media entity for player/plugins config purposes.
 */
class SambaMediaConfig : SambaMedia {

	var id = ""
	var projectHash = ""
	var projectId = 0
	var categoryId = 0
	var sessionId = Helpers.getSessionId()
	var sttmUrl = "http://sttm.sambatech.com.br/collector/__sttm.gif"
	var sttmKey = "ae810ebc7f0654c4fadc50935adcf5ec"
}
