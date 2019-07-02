//
//  Helpers.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import UIKit

class Helpers {
	static let settings = NSDictionary.init(contentsOfFile: Bundle(for:Helpers.self).path(forResource: "Settings", ofType: "plist")!)! as! [String:String]
	static let requestTimeout = TimeInterval(30)
    
    static let imageCache = NSCache<NSString, UIImage>()
	
	static func matchesForRegexInText(_ regex: String!, text: String!) -> [String] {
		do {
			let regex = try NSRegularExpression(pattern: regex, options: [])
			let nsString = text as NSString
			let results = regex.matches(in: text,
				options: [], range: NSMakeRange(0, nsString.length))
			
			return results.map { nsString.substring(with: $0.range) }
		}
		catch let error as NSError {
			print("Error: Invalid regex: \(error.localizedDescription)")
		}
		catch {
			print("Error: Some other regex error!")
		}
		
		return []
	}
	
	static func getTopMostVC() -> UIViewController? {
		func f(_ vc: UIViewController?) -> UIViewController? {
			return vc?.presentedViewController == nil ? vc : f(vc?.presentedViewController)
		}
		
		return f(UIApplication.shared.keyWindow?.rootViewController)
	}
	
	static func getSessionId() -> String {
		func getSessionComponent() -> String {
			let n = String(format: "%x", Int(arc4random()>>16) + Int(UInt16.max))
			return n.substring(from: n.characters.index(n.startIndex, offsetBy: 1))
		}
		
		var s = ""
		
		for i in 0...7 {
			s += getSessionComponent()
			
			switch i {
			case 1: fallthrough
			case 2: fallthrough
			case 3: fallthrough
			case 4:
				s += "-"
			default: break
			}
		}
		
		return s
	}
	
	static func requestURL(_ url: String) {
		requestURL(url, nil as ((Data?) -> Void)?)
	}
	
	static func requestURL<T>(_ url: String, _ onComplete: ((T?) -> Void)?) {
		requestURL(url, onComplete, nil)
	}
	
	static func requestURL<T>(_ url: String, _ onComplete: ((T?) -> Void)?, _ onError: ((Error?, URLResponse?) -> Void)? = nil) {
		guard let url = URL(string: url) else {
			print("\(type(of: self)) Error: Invalid URL format.")
			return
		}
		
		requestURL(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: requestTimeout),
		           onComplete, onError)
	}
	
	static func requestURL<T>(_ urlRequest: URLRequest, _ onComplete: ((T?) -> Void)?) {
		requestURL(urlRequest, onComplete, nil)
	}
	
	static func requestURL(_ urlRequest: URLRequest) {
		requestURL(urlRequest, nil as ((Data?) -> Void)?)
	}
	
	static func requestURL<T>(_ urlRequest: URLRequest, _ onComplete: ((T?) -> Void)?, _ onError: ((Error?, URLResponse?) -> Void)? = nil) {
		let requestTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
			let reqText = "\n\(urlRequest.url?.absoluteString ?? "")\nMethod: \(urlRequest.httpMethod ?? "")\nHeader: \(String(describing: urlRequest.allHTTPHeaderFields))"
			
			if let error = error {
				print("\(type(of: self)) Error: \(error.localizedDescription)\(reqText)")
				onError?(error, response)
				return
			}
			
			guard let res = response as? HTTPURLResponse else {
				print("\(type(of: self)) Error: No response from server.\(reqText)")
				onError?(error, response)
				return
			}
			
			guard case 200..<300 = res.statusCode else {
				print("\(type(of: self)) Error: Invalid server response (\(res)).\(reqText)")
				onError?(error, response)
				return
			}
			
			guard let data = data else {
				print("\(type(of: self)) Error: Unable to get data.\(reqText)")
				onError?(error, response)
				return
			}
			
			switch T.self {
			case is String.Type:
				if let text = String(data: data, encoding: .utf8) {
					onComplete?(text as? T)
				}
				else if let text = String(data: data, encoding: .ascii) {
					onComplete?(text as? T)
				}
				else {
					print("\(type(of: self)) Error: Unable to get text response.\(reqText)")
				}
			case is Data.Type:
				onComplete?(data as? T)
			default:
				onError?(nil, response)
			}
		}
		
		requestTask.resume()
	}
    
    
    static func requestURLWithHttpResponse<T>(_ urlRequest: URLRequest,  _ onComplete: ((T?, HTTPURLResponse?) -> Void)?, _ onError: ((Error?, URLResponse?) -> Void)? = nil) {
        let requestTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in

            if let error = error {
                onError?(error, response)
                return
            }
            
            onComplete?(data as? T, response as? HTTPURLResponse)
        }
        
        requestTask.resume()
    }
	
	static func requestURLJson(_ url: String, _ onComplete: @escaping (AnyObject?) -> Void, _ onError: ((Error?, URLResponse?) -> Void)? = nil) {
		requestURL(url, { (data: Data?) in
			var jsonOpt: AnyObject?
			let onError = onError ?? { (error, response) in }
			
			do {
				if let data = data {
					jsonOpt = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
				}
				else {
					print("\(type(of: self)) Error getting JSON data.")
					onError(nil, nil)
				}
			}
			catch {
				print("\(type(of: self)) Error parsing JSON string.")
				onError(nil, nil)
			}
			
			onComplete(jsonOpt)
		}, onError)
	}
    
    static func isConnectedToInternet() -> Bool {
        let hostname = "google.com"
        let hostinfo = gethostbyname2(hostname, AF_INET6)//AF_INET6
        if hostinfo != nil {
            return true // internet available
        }
        return false // no internet
    }
    
    private static func DarwinVersion() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let dv = String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        return "Darwin/\(dv)"
    }
    
    private static func CFNetworkVersion() -> String {
        let dictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary!
        let version = dictionary?["CFBundleShortVersionString"] as! String
        return "CFNetwork/\(version)"
    }
    
    
    private static func deviceVersion() -> String {
        let currentDevice = UIDevice.current
        return "\(currentDevice.systemName)/\(currentDevice.systemVersion)"
    }
    
    private static func deviceName() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    private static func appNameAndVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let name = dictionary["CFBundleName"] as! String
        return "\(name)/\(version)"
    }
    
    static func getUserAgentString() -> String {
        return "\(appNameAndVersion()) \(deviceName()) \(deviceVersion()) \(CFNetworkVersion()) \(DarwinVersion())"
    }
    
    static func downloadImage(from url: String, completion: @escaping (_ image: UIImage?,_ error: Error?) -> Void) {
        if let cachedImage = imageCache.object(forKey: url as NSString) {
            DispatchQueue.main.async {
                completion(cachedImage, nil)
            }
        } else {
            let requestTask = URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
    
                if let error = error {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                } else if let data = data, let image = UIImage(data: data) {
                    imageCache.setObject(image, forKey: url as NSString)
                    DispatchQueue.main.async {
                        completion(image, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                       completion(nil, NSError())
                    }
                }
                
            }
            requestTask.resume()
        }
    }
    
    static func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            } catch {
            }
        }
        return nil
    }
    
}

extension UIColor {
	convenience init(_ rgba: UInt) {
		let t = rgba > 0xFFFFFF ? 3 : 2
		
		var array = [CGFloat](repeating: 1.0, count: 4)
		var n: UInt
		
		for i in 0...t {
			n = UInt((t - i)*8)
			array[i] = CGFloat((rgba & 0xFF << n) >> n)/255.0
		}
		
		self.init(red: array[0], green: array[1], blue: array[2], alpha: array[3])
	}
}

extension String {
	func match(_ regex: String) -> String? {
		guard let range = self.range(of: regex, options: .regularExpression) else {
			return nil
		}
		
        return String(self[range])
	}
}

public extension UIImage {
	/**
	Tint, Colorize image with given tint color<br><br>
	This is similar to Photoshop's "Color" layer blend mode<br><br>
	This is perfect for non-greyscale source images, and images that have both highlights and shadows that should be preserved<br><br>
	white will stay white and black will stay black as the lightness of the image is preserved<br><br>
	
	<img src="http://yannickstephan.com/easyhelper/tint1.png" height="70" width="120"/>
	
	**To**
	
	<img src="http://yannickstephan.com/easyhelper/tint2.png" height="70" width="120"/>
	
	- parameter tintColor: UIColor
	
	- returns: UIImage
	*/
	public func tintPhoto(_ tintColor: UIColor) -> UIImage {
		
		return modifiedImage { context, rect in
			// draw black background - workaround to preserve color of partially transparent pixels
			context.setBlendMode(.normal)
			UIColor.black.setFill()
			context.fill(rect)
			
			// draw original image
			context.setBlendMode(.normal)
			context.draw(self.cgImage!, in: rect)
			
			// tint image (loosing alpha) - the luminosity of the original image is preserved
			context.setBlendMode(.color)
			tintColor.setFill()
			context.fill(rect)
			
			// mask by alpha values of original image
			context.setBlendMode(.destinationIn)
			context.draw(self.cgImage!, in: rect)
		}
	}
	/**
	Tint Picto to color
	
	- parameter fillColor: UIColor
	
	- returns: UIImage
	*/
	public func tintPicto(_ fillColor: UIColor) -> UIImage {
		
		return modifiedImage { context, rect in
			// draw tint color
			context.setBlendMode(.normal)
			fillColor.setFill()
			context.fill(rect)
			
			// mask by alpha values of original image
			context.setBlendMode(.destinationIn)
			context.draw(self.cgImage!, in: rect)
		}
	}
	/**
	Modified Image Context, apply modification on image
	
	- parameter draw: (CGContext, CGRect) -> ())
	
	- returns: UIImage
	*/
	private func modifiedImage(_ draw: (CGContext, CGRect) -> ()) -> UIImage {
		
		// using scale correctly preserves retina images
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		let context: CGContext! = UIGraphicsGetCurrentContext()
		assert(context != nil)
		
		// correctly rotate image
		context.translateBy(x: 0, y: size.height);
		context.scaleBy(x: 1.0, y: -1.0);
		
		let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
		
		draw(context, rect)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image!
	}
}
