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



/// Manages media data requests
@objc public class SambaApi : NSObject {
	/**
	Default constructor
	*/
	public override init() {}
	
	/**
	Requests and decodes a Base64 media data from the Samba Player API
	
	- parameter request: The request to the API
	- parameter onComplete: The callback when the request completes that brings the media object to use with the player
	*/
	@objc public func requestMedia(_ request: SambaMediaRequest, onComplete: @escaping (SambaMedia?) -> Void) {
		requestMedia(request, onComplete: onComplete, onError: nil)
	}
    
    @objc public func prepareOfflineMedia(media: SambaMedia, onComplete: @escaping (SambaMedia?) -> Void, onError: @escaping (Error?, URLResponse?) -> Void) {
        
        if media.isOffline {
            
            let sambaMediaConfig = media as! SambaMediaConfig
            
            if sambaMediaConfig.drmRequest != nil && OfflineUtils.isContentKeyExpired(for: sambaMediaConfig.id) {
                requestMedia(SambaMediaRequest(projectHash: sambaMediaConfig.projectHash, mediaId: sambaMediaConfig.id), onComplete: { (media) in
                    media?.isOffline = true
                    media?.isCaptionsOffline = sambaMediaConfig.isCaptionsOffline
                    
                    let config = media as! SambaMediaConfig
                    
                    if config.drmRequest != nil {
                        config.drmRequest?.token = sambaMediaConfig.drmRequest?.token
                    }
                    
                    SambaDownloadManager.sharedInstance.updateMedia(for: config)
                    onComplete(media)
                }) { (error, response) in
                    onComplete(media)
                }
            } else {
               onComplete(media)
            }
        } else {
            onError(nil, nil)
        }
    }
	
	/**
	Requests and decodes a Base64 media data from the Samba Player API
	
	- parameter request: The request to the API
	- parameter onComplete: The callback when the request completes that brings the media object to use with the player
	- parameter onError: The callback for any error during the API request
	*/
	@objc public func requestMedia(_ request: SambaMediaRequest, onComplete: @escaping (SambaMedia?) -> Void, onError: ((Error?, URLResponse?) -> Void)? = nil) {
		
		let endpointOpt: String?
		
		switch request.environment {
		case .local:
			endpointOpt = Helpers.settings["playerapi_endpoint_local"]
		case .test:
			endpointOpt = Helpers.settings["playerapi_endpoint_test"]
		case .staging:
			endpointOpt = normalizeProtocol(url: Helpers.settings["playerapi_endpoint_staging"]!, apiProtocol: request.apiProtocol)
		case .prod: fallthrough
		default:
			endpointOpt = normalizeProtocol(url: Helpers.settings["playerapi_endpoint_prod"]!, apiProtocol: request.apiProtocol)
		}
		
		guard let endpoint = endpointOpt else {
			fatalError("Error trying to fetch info in Settings.plist")
		}
		
		var url = "\(endpoint)\(request.projectHash)/"
		
		if let mediaId = request.mediaId {
			url += mediaId
		}
		else if let liveChannelId = request.liveChannelId {
			url += "live/\(liveChannelId)"
		}
		
		if let streamUrl = request.streamUrl {
			url += "?alternateLive=\(streamUrl)"
		}
		else if let streamName = request.streamName {
			url += "?streamName=\(streamName)"
		}
		
		print("\(type(of: self)) Requesting URL: \(url)")
		
		Helpers.requestURL(url, { (responseText: String?) in
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
				onComplete(self.parseMedia(try JSONSerialization.jsonObject(with: jsonText, options: .allowFragments) as AnyObject, request: request))
			}
			catch {
				print("\(type(of: self)) Error: Failed to parse JSON string.")
			}
		}, onError)
	}
	
	
	// Collects media info and its outputs.
	private func parseMedia(_ json: AnyObject, request: SambaMediaRequest) -> SambaMedia? {
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
		let playerConfig = json["playerConfig"]!! as AnyObject
		let apiConfig = json["apiConfig"]!! as AnyObject
		let project = json["project"]!! as AnyObject
		
		media.projectHash = project["playerHash"] as! String
		media.projectId = project["id"] as! Int
        media.clientId = project["clientId"] as! Int
		media.isAudio = request.isLiveAudio || qualifier.lowercased() == "audio"
		
		if let title = json["title"] as? String {
			media.title = title
		}
		
		if let id = json["id"] as? String {
			media.id = id
		}
		
		if let categoryId = json["categoryId"] as? Int {
			media.categoryId = categoryId
		}
		
		if let theme = playerConfig["theme"] as? String, theme.lowercased() != "default" {
			media.theme = UInt(theme.replacingOccurrences(of: "^#*", with: "", options: .regularExpression), radix: 16)!
            media.themeColorHex = "#\(theme)"
		}
		
		if let sttm = apiConfig["sttm"] as? [String:AnyObject] {
			if let url = sttm["url"] as? String {
				media.sttmUrl = normalizeProtocol(url: url, apiProtocol: request.apiProtocol)
			}
			
			if let key = sttm["key"] as? String {
				media.sttmKey = key
			}
		}
		
		if let ads = json["advertisings"] as? [AnyObject] {
			if ads.count > 0, let ad = ads[0] as? [String:AnyObject],
				let url = ad["tagVast"] as? String,
				ad["adServer"]?.lowercased == "dfp" {
				media.adUrl = normalizeProtocol(url: url, apiProtocol: request.apiProtocol)
			}
		}
		
		if let rules = json["deliveryRules"] as? [AnyObject] {
			let defaultOutput = project["defaultOutput"] as? String ?? "240p"
			var deliveryOutputsCount = [String:Int]()
			var deliveryType: String
			var defaultOutputCurrent: String
			var label: String
			var mediaOutputs: [SambaMediaOutput]
			
			for rule in rules {
				deliveryType = (rule["urlType"] as! String).lowercased()
				
				// restricts media to HLS or PROGRESSIVE
				// delivery rule must have at least one output
				// if already registered, make sure PROGRESSIVE won't overwrite HLS
				// otherwise see if current rule have more outputs than the registered one
				guard deliveryType == "hls" || deliveryType == "progressive",
					let outputs = rule["outputs"] as? [AnyObject],
						outputs.count > 0
							&& (deliveryType != "progressive" || media.deliveryType != "hls")
							&& (deliveryOutputsCount[deliveryType] == nil
							|| outputs.count > deliveryOutputsCount[deliveryType]) else {
					continue
				}
				
				deliveryOutputsCount[deliveryType] = outputs.count
				defaultOutputCurrent = deliveryType == "hls" ? "abr" : defaultOutput
				mediaOutputs = []
				media.deliveryType = deliveryType
				
				for output in outputs {
					label = (output["outputName"] as! String).lowercased()
					
					// if audio, raw file can be considered
					guard media.isAudio || label != "_raw",
						let url = output["url"] as? String else {
						continue
					}
					
					let urlNormalized = normalizeProtocol(url: url, apiProtocol: request.apiProtocol)
                    
                    if let fileInfo = output["fileInfo"] as? NSDictionary {
                        
                        if let duration = fileInfo["duration"] as? CLong {
                            media.duration = Float(duration/1000)
                        }
                        
                        if let bitrate = fileInfo["bitrate"] as? CLong {
                            media.bitrate = bitrate
                        }
                    }
                    
                    
					mediaOutputs.append(SambaMediaOutput(
						url: urlNormalized,
						label: label.contains("abr") ? "Auto" : label,
						isDefault: label.contains(defaultOutputCurrent)
					))
				}
				
				media.outputs = mediaOutputs.sorted(by: { Int($0.label.match("^\\d+") ?? "0") < Int($1.label.match("^\\d+") ?? "0") })
			}
		}
		else if let liveOutput = json["liveOutput"] as? [String:AnyObject],
			let url = (liveOutput["primaryURL"] ?? liveOutput["baseUrl"]) as? String {
			media.url = url
			media.url = normalizeProtocol(url: media.url!, apiProtocol: request.apiProtocol)
			media.backupUrls = request.backupUrls
			
			if let url = liveOutput["backupURL"] as? String {
				media.backupUrls.append(url)
			}
			
			media.isDvr = liveOutput["dvr"] as? Bool ?? false
			media.isLive = true
		}
		
		if let thumbs = json["thumbnails"] as? [AnyObject] , thumbs.count > 0 {
			let wGoal = Int(UIScreen.main.bounds.size.width)
			var url: String?
			var wLast = 0
			
			for thumb in thumbs {
				guard let w = thumb["width"] as? Int,
					abs(w - wGoal) < abs(wLast - wGoal)
					else { continue }
				
				url = thumb["url"] as? String
				url = normalizeProtocol(url: url!, apiProtocol: request.apiProtocol)
				wLast = w
			}
			
			if let url = url,
				let nsurl = URL(string: url),
				let data = try? Data(contentsOf: nsurl) {
                media.thumbURL = url
				media.thumb = UIImage(data: data)
			}
		}
		
		if let captions = json["captions"] as? [AnyObject], captions.count > 0 {
			var mediaCaptions = [SambaMediaCaption]()
			let langLookup = [
				"pt-br": "Português",
				"en-us": "Inglês",
				"es-es": "Espanhol",
				"it-it": "Italiano",
				"fr-fr": "Francês",
				"disable": "Desativar"
			]
			
			for caption in captions {
				guard let url = caption["url"] as? String,
					let info = caption["fileInfo"] as? [String:AnyObject],
					let lang = info["captionLanguage"] as? String,
					// TODO: localization
					let label = langLookup[lang.lowercased().replacingOccurrences(of: "_", with: "-")]
					else { continue }
				
				let normalizedURL = normalizeProtocol(url: url, apiProtocol: request.apiProtocol)
				
				mediaCaptions.append(SambaMediaCaption(
					url: normalizedURL,
					//label: NSLocalizedString(lang.lowercased().replacingOccurrences(of: "_", with: "-"), tableName: nil, bundle: Bundle.init(for: this), value: "", comment: ""),
					label: label + (info["autoGenerated"] as? Bool ?? false ? " (auto)" : ""),
					language: lang,
					cc: info["closedCaption"] as? Bool ?? false,
					isDefault: false
				))
			}
			
			// set disable option (as default)
			if let label = langLookup["disable"] {
				mediaCaptions.append(SambaMediaCaption(
					url: "",
					label: label,
					language: "",
					cc: false,
					isDefault: true
				))
			}
			
			media.captions = mediaCaptions
		}
		
		if let sec = json["playerSecurity"] as? [String:AnyObject] {
			if let drmSecurity = sec["drmSecurity"] as? [String:AnyObject],
				let licenseUrl = drmSecurity["fairplaySignatureURL"] as? String {
				let drm = DrmRequest("\(licenseUrl)/getcertificate", "\(licenseUrl)getckc")
                drm.addLicenseParam(key: "CrmId", value: drmSecurity["crmId"] as? String)
                drm.addLicenseParam(key: "AccountId", value: drmSecurity["accountId"] as? String)
                drm.addLicenseParam(key: "ContentId", value: drmSecurity["contentId"] as? String)
                drm.provider = drmSecurity["provider"] as? String
                drm.applicationID = drmSecurity["applicationId"] as? String
                
                if drm.provider == "SAMBA_DRM", let applicationId = drm.applicationID  {
                    drm.addACParam(key: "applicationId", value:  applicationId)
                } else {
                    drm.addACParam(key: "applicationId", value:  "sambatech")
                }
                
				media.drmRequest = drm
			}
			
			if let rootedDevices = sec["rootedDevices"] as? String {
				media.blockIfRooted = rootedDevices.lowercased() == "true"
			}
		}
		
		return media
	}
	
	//Normaliza URLS
	private func normalizeProtocol(url: String, apiProtocol: SambaProtocol) -> String {
		let normalized = url.replacingOccurrences(of: "https?", with: apiProtocol.rawValue, options: .regularExpression)
		return normalized
	}
}
