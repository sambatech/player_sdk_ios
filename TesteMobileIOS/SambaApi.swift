//
//  SambaApi.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/9/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import Alamofire

public class SambaApi {
	
	public func requestMedia(request: SambaMediaRequest, callback: SambaMedia? -> ()) {
		Alamofire.request(.GET, Commons.settings["playerapi_endpoint"]! + request.projectHash + (request.mediaId != nil ? "/" + request.mediaId! : "")).responseString { response in
			guard let token = response.result.value else {
				print("\(self.dynamicType) Error: No media response data!")
				return
			}

			var tokenBase64: String = token
			
			if let mediaId = request.mediaId,
					m = mediaId.rangeOfString("\\d(?=[a-zA-Z]*$)", options: .RegularExpressionSearch),
					delimiter = Int(mediaId[m]) {
				tokenBase64 = token.substringWithRange(token.startIndex.advancedBy(delimiter)..<token.endIndex.advancedBy(-delimiter))
			}
			
			tokenBase64 = tokenBase64.stringByReplacingOccurrencesOfString("-", withString: "+")
				.stringByReplacingOccurrencesOfString("_", withString: "/")
			
			switch tokenBase64.characters.count % 4 {
			case 2:
				tokenBase64 += "=="
			case 3:
				tokenBase64 += "="
			default: break
			}
			
			guard let data = NSData(base64EncodedString: tokenBase64, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) else {
				print("\(self.dynamicType) Error: Base64 token failed to create encoded data")
				return
			}
			
			do {
				callback(self.parseMedia(try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)))
			}
			catch {
				print("\(self.dynamicType) Error: Failed to parse JSON string")
			}
		}
	}
	
	private func parseMedia(json: AnyObject) -> SambaMedia? {
		guard let qualifier = json["qualifier"] as? String else {
			print("\(self.dynamicType) Error: No media qualifier")
			return nil
		}
		
		switch qualifier.lowercaseString {
		case "video", "live": break
		default:
			print("\(self.dynamicType) Error: Invalid media qualifier")
			return nil
		}
		
		let media = SambaMediaConfig()
		let playerConfig = json["playerConfig"]!!
		
		if let title = json["title"] as? String {
			media.title = title
		}
		
		if let id = json["id"] as? String {
			media.id = id
		}
		
		if let categoryId = json["categoryId"] as? Int {
			media.categoryId = categoryId
		}
		
		if let theme = playerConfig["theme"] as? String where theme.lowercaseString != "default",
				let color = Int.init(theme.stringByReplacingOccurrencesOfString("^#*", withString: ""), radix: 16) {
			media.theme = color
		}
		
		if let project = json["project"]! {
			media.projectHash = project["playerHash"] as! String
			media.projectId = project["id"] as! Int
		}
		
		if let _ = json["deliveryRules"] {
			
		}
		else if let liveOutput = json["liveOutput"] as? String {
			media.isLive = true
			media.url = liveOutput
		}
		
		return media
	}
}
