//
//  SambaApi.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}




@objc open class SambaApi : NSObject {
	
	/**
	Default constructor
	
	*/
	public override init() {}
	
	/**
	Request media from SambaPlayer API<br><br>
	The SambaPlayer API returns a base64 string with the encoded media info and its decoded before intiate
	
	- Parameters:
		- request: SambaMediaRequest - Request to our api
		- callback: SambaMedia - Callback when the request is made passing our SambaMedia object
	
	*/
	open func requestMedia(_ request: SambaMediaRequest, callback: @escaping (SambaMedia?) -> ()) {
		Helpers.requestURL("\(Helpers.settings["playerapi_endpoint"]!)\(request.projectHash)/" + (request.mediaId ??
			"?\((request.streamUrls ?? []).count > 0 ? "alternateLive=\(request.streamUrls![0])" : "streamName=\(request.streamName!)")")) { responseText in
			guard let responseText = responseText else { return }
			
			var tokenBase64: String = responseText
			
			if let mediaId = request.mediaId,
					let m = mediaId.range(of: "\\d(?=[a-zA-Z]*$)", options: .regularExpression),
					let delimiter = Int(mediaId[m]) {
				tokenBase64 = responseText.substring(with: responseText.characters.index(responseText.startIndex, offsetBy: delimiter)..<responseText.characters.index(responseText.endIndex, offsetBy: -delimiter))
			}
			
			tokenBase64 = tokenBase64.replacingOccurrences(of: "-", with: "+")
				.replacingOccurrences(of: "_", with: "/")
			
			switch tokenBase64.characters.count % 4 {
			case 2:
				tokenBase64 += "=="
			case 3:
				tokenBase64 += "="
			default: break
			}
			
			guard let jsonText = Data(base64Encoded: tokenBase64, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) else {
				print("\(type(of: self)) Error: Base64 token failed to create encoded data.")
				return
			}
			
			do {
				callback(self.parseMedia(try JSONSerialization.jsonObject(with: jsonText, options: .allowFragments), request: request))
			}
			catch {
				print("\(type(of: self)) Error: Failed to parse JSON string.")
			}
		}
	}
	
	
	//Colect the important media info and its desired outputs<br><br>
	fileprivate func parseMedia(_ json: AnyObject, request: SambaMediaRequest) -> SambaMedia? {
		guard let qualifier = json["qualifier"] as? String else {
			print("\(type(of: self)) Error: No media qualifier")
			return nil
		}
		
		switch qualifier.lowercased() {
		case "video", "live", "audio": break
		default:
			print("\(type(of: self)) Error: Invalid media qualifier")
			return nil
		}
		
		let media = SambaMediaConfig()
		let playerConfig = json["playerConfig"]!!
		let apiConfig = json["apiConfig"]!!
		let project = json["project"]!!
		
		media.projectHash = project["playerHash"] as! String
		media.projectId = project["id"] as! Int
		media.isAudio = request.isLiveAudio ?? (qualifier.lowercased() == "audio")
		
		if let title = json["title"] as? String {
			media.title = title
		}
		
		if let id = json["id"] as? String {
			media.id = id
		}
		
		if let categoryId = json["categoryId"] as? Int {
			media.categoryId = categoryId
		}
		
		if let theme = playerConfig["theme"] as? String , theme.lowercased() != "default" {
			media.theme = UInt(theme.replacingOccurrences(of: "^#*", with: "", options: .regularExpression), radix: 16)!
		}
		
		if let sttm = apiConfig["sttm"] as? [String:AnyObject] {
			if let url = sttm["url"] as? String {
				media.sttmUrl = url
			}
			
			if let key = sttm["key"] as? String {
				media.sttmKey = key
			}
		}
		
		if let ads = json["advertisings"] as? [AnyObject] {
			if ads.count > 0, let ad = ads[0] as? [String:AnyObject],
				let url = ad["tagVast"] as? String
				, ad["adServer"]?.lowercased == "dfp" {
				media.adUrl = url
			}
		}
		
		if let rules = json["deliveryRules"] as? [AnyObject] {
			let defaultOutput = project["defaultOutput"] as? String ?? "240p"
			var deliveryOutputsCount = [String:Int]()
			var deliveryType: String
			var defaultOutputCurrent: String
			var label: String
			var mediaOutputs: [SambaMedia.Output]
			
			for rule in rules {
				deliveryType = (rule["urlType"] as! String).lowercased()
				
				// restricts media to HLS or PROGRESSIVE
				// delivery rule must have at least one output
				// if already registered, make sure PROGRESSIVE won't overwrite HLS
				// otherwise see if current rule have more outputs than the registered one
				guard deliveryType == "hls" || deliveryType == "progressive",
					let outputs = rule["outputs"] as? [AnyObject]
						, outputs.count > 0
							&& (deliveryType != "progressive" || media.deliveryType != "hls")
							&& (deliveryOutputsCount[deliveryType] == nil
							|| outputs.count > deliveryOutputsCount[deliveryType]) else {
					continue
				}
				
				deliveryOutputsCount[deliveryType] = outputs.count
				defaultOutputCurrent = deliveryType == "hls" ? "abr_hls" : defaultOutput
				mediaOutputs = []
				media.deliveryType = deliveryType
				
				for output in outputs {
					label = (output["outputName"] as! String).lowercased()
					
					// if audio, raw file can be considered
					guard media.isAudio || label != "_raw",
						let url = output["url"] as? String else {
						continue
					}
					
					mediaOutputs.append(SambaMedia.Output(
						url: url,
						label: label == "abr_hls" ? "Auto" : label,
						isDefault: label == defaultOutputCurrent
					))
				}
				
				media.outputs = mediaOutputs.sorted(by: { Int($0.label.match("^\\d+") ?? "0") < Int($1.label.match("^\\d+") ?? "0") })
			}
		}
		else if let liveOutput = json["liveOutput"] as? [String:AnyObject] {
			media.url = liveOutput["baseUrl"] as? String
			media.isLive = true
		}
		
		if let thumbs = json["thumbnails"] as? [AnyObject] , thumbs.count > 0 {
			let wGoal = Int(UIScreen.main.bounds.size.width)
			var url: String?
			var wLast = 0
			
			for thumb in thumbs {
				guard let w = thumb["width"] as? Int
					, abs(w - wGoal) < abs(wLast - wGoal)
					else { continue }
				
				url = thumb["url"] as? String
				wLast = w
			}
			
			if let url = url,
				let nsurl = URL(string: url),
				let data = try? Data(contentsOf: nsurl) {
				media.thumb = UIImage(data: data)
			}
		}
		
		return media
	}
}
