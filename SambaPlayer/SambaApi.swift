//
//  SambaApi.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation

@objc public class SambaApi : NSObject {
	
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
	public func requestMedia(request: SambaMediaRequest, callback: SambaMedia? -> ()) {
		Helpers.requestURL("\(Helpers.settings["playerapi_endpoint"]!)\(request.projectHash)/" + (request.mediaId ??
			"?\((request.streamUrls ?? []).count > 0 ? "alternateLive=\(request.streamUrls![0])" : "streamName=\(request.streamName!)")")) { responseText in
			guard let responseText = responseText else { return }
			
			var tokenBase64: String = responseText
			
			if let mediaId = request.mediaId,
					m = mediaId.rangeOfString("\\d(?=[a-zA-Z]*$)", options: .RegularExpressionSearch),
					delimiter = Int(mediaId[m]) {
				tokenBase64 = responseText.substringWithRange(responseText.startIndex.advancedBy(delimiter)..<responseText.endIndex.advancedBy(-delimiter))
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
			
			guard let jsonText = NSData(base64EncodedString: tokenBase64, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) else {
				print("\(self.dynamicType) Error: Base64 token failed to create encoded data.")
				return
			}
			
			do {
				callback(self.parseMedia(try NSJSONSerialization.JSONObjectWithData(jsonText, options: .AllowFragments), request: request))
			}
			catch {
				print("\(self.dynamicType) Error: Failed to parse JSON string.")
			}
		}
	}
	
	
	//Colect the important media info and its desired outputs<br><br>
	private func parseMedia(json: AnyObject, request: SambaMediaRequest) -> SambaMedia? {
		guard let qualifier = json["qualifier"] as? String else {
			print("\(self.dynamicType) Error: No media qualifier")
			return nil
		}
		
		switch qualifier.lowercaseString {
		case "video", "live", "audio": break
		default:
			print("\(self.dynamicType) Error: Invalid media qualifier")
			return nil
		}
		
		let media = SambaMediaConfig()
		let playerConfig = json["playerConfig"]!!
		let apiConfig = json["apiConfig"]!!
		let project = json["project"]!!
		
		media.projectHash = project["playerHash"] as! String
		media.projectId = project["id"] as! Int
		media.isAudio = request.isLiveAudio ?? (qualifier.lowercaseString == "audio")
		
		if let title = json["title"] as? String {
			media.title = title
		}
		
		if let id = json["id"] as? String {
			media.id = id
		}
		
		if let categoryId = json["categoryId"] as? Int {
			media.categoryId = categoryId
		}
		
		if let theme = playerConfig["theme"] as? String where theme.lowercaseString != "default" {
			media.theme = UInt(theme.stringByReplacingOccurrencesOfString("^#*", withString: "", options: .RegularExpressionSearch), radix: 16)!
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
				url = ad["tagVast"] as? String
				where ad["adServer"]?.lowercaseString == "dfp" {
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
				deliveryType = (rule["urlType"] as! String).lowercaseString
				
				// restricts media to HLS or PROGRESSIVE
				// delivery rule must have at least one output
				// if already registered, make sure PROGRESSIVE won't overwrite HLS
				// otherwise see if current rule have more outputs than the registered one
				guard deliveryType == "hls" || deliveryType == "progressive",
					let outputs = rule["outputs"] as? [AnyObject]
						where outputs.count > 0
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
					label = (output["outputName"] as! String).lowercaseString
					
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
				
				media.outputs = mediaOutputs.sort({ Int($0.label.match("^\\d+") ?? "0") < Int($1.label.match("^\\d+") ?? "0") })
			}
		}
		else if let liveOutput = json["liveOutput"] as? [String:AnyObject] {
			media.url = liveOutput["baseUrl"] as? String
			media.isLive = true
		}
		
		return media
	}
}
