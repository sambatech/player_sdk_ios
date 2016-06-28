//
//  SambaModel.swift
//
//
//  Created by Leandro Zanol on 3/3/16.
//
//

/**
 * Data entity representing a media.
 *
 * If `outputs` field is nil, use `url` field.
 */
@objc public class SambaMedia : NSObject {

	public struct Output {
		let url: String, label: String, isDefault: Bool
	}

	public var title = ""
	public var url: String? {
		didSet {
			guard let urlNonNull = url else { return }

			if let _ = urlNonNull.rangeOfString("\\.m3u8$", options: .RegularExpressionSearch) {
				deliveryType = "hls"
			}
			else if let _ = urlNonNull.rangeOfString("\\.(mp4|mov)$", options: .RegularExpressionSearch) {
				deliveryType = "progressive"
			}
		}
	}
	public var adUrl: String?
	public var outputs: [SambaMedia.Output]?
	public var deliveryType = "other"
	public var thumb: String?
	public var isLive = false;
	public var theme: UInt = 0x72BE44

	public override init() {}

	public convenience init(_ url:String) {
		self.init(url, title: nil, thumb: nil)
	}

	public init(_ url:String, title:String?, thumb:String?) {
		self.title = title ?? ""
		self.url = url
		self.thumb = thumb
	}
	
	public override var description: String { return title; }
}

/**
 * Internal extension of the media entity for player/plugins config purposes.
 */
class SambaMediaConfig : SambaMedia {

	var id = ""
	var projectHash = ""
	var projectId = 0
	var categoryId = 0;
	var sessionId = Helpers.getSessionId()
	var sttmUrl = "http://sttm.sambatech.com.br/collector/__sttm.gif"
	var sttmKey = "ae810ebc7f0654c4fadc50935adcf5ec"
}
