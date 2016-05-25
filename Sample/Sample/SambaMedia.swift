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
public class SambaMedia : CustomStringConvertible {
	
	public struct Output {
		let url: String, label: String, isDefault: Bool
	}
	
	public var title: String = ""
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
	public var outputs: [SambaMedia.Output]?
	public var deliveryType: String = "other"
	public var thumb: String?
	public var isLive = false;
	//public var theme: Int = 0x72BE44
	public var theme: String = "#72BE44"
	
	init() {}
	
	public convenience init(_ url:String) {
		self.init(url, title: nil, thumb: nil)
	}
	
	public init(_ url:String, title:String?, thumb:String?) {
		self.title = title ?? ""
		self.url = url
		self.thumb = thumb
	}
	
	public var description: String { return title; }
}

/**
 * Internal extension of the media entity for player/plugins config purposes.
 */
class SambaMediaConfig : SambaMedia {
	
	var id: String = ""
	var projectHash: String = ""
	var projectId: Int = 0
	var categoryId: Int = 0;
	//public sessionId: String = Helpers.getSessionId();
}
