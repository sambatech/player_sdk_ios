//
//  Commons.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/8/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import UIKit

class Helpers {
	static let settings = NSDictionary.init(contentsOfFile: NSBundle.mainBundle().pathForResource("Configs", ofType: "plist")!)! as! [String:String]
	
	static func requestURLJson(url: String, _ callback: ([AnyObject]? -> ())) {
		guard let url = NSURL(string: url) else {
			print("\(self.dynamicType) Error: Invalid URL format.")
			return
		}
		
		let requestTask = NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: url)) { data, response, error in
			dispatch_async(dispatch_get_main_queue()) {
				if let error = error {
					print("\(self.dynamicType) Error: \(error.localizedDescription)")
					callback(nil)
					return
				}
				
				guard let response = response as? NSHTTPURLResponse else {
					print("\(self.dynamicType) Error: No response from server.")
					callback(nil)
					return
				}
				
				guard case 200..<300 = response.statusCode else {
					print("\(self.dynamicType) Error: Invalid server response (\(response.statusCode)).")
					callback(nil)
					return
				}
				
				guard let jsonData = data else {
					print("\(self.dynamicType) Error: \(error?.description ?? "Unable to get data.")")
					callback(nil)
					return
				}
				
				var jsonOpt: [AnyObject]?
				
				do {
					jsonOpt = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as? [AnyObject]
				}
				catch {
					print("\(self.dynamicType) Error parsing JSON string.")
					callback(nil)
					return
				}
				
				callback(jsonOpt)
			}
		}
		
		requestTask.resume()
	}
}

extension UIColor {
	convenience init(_ rgba: UInt) {
		let t = rgba > 0xFFFFFF ? 3 : 2
		
		var array = [CGFloat](count: 4, repeatedValue: 1.0)
		var n: UInt
		
		for i in 0...t {
			n = UInt((t - i)*8)
			array[i] = CGFloat((rgba & 0xFF << n) >> n)/255.0
		}
		
		self.init(red: array[0], green: array[1], blue: array[2], alpha: array[3])
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
	public func tintPhoto(tintColor: UIColor) -> UIImage {
		
		return modifiedImage { context, rect in
			// draw black background - workaround to preserve color of partially transparent pixels
			CGContextSetBlendMode(context, .Normal)
			UIColor.blackColor().setFill()
			CGContextFillRect(context, rect)
			
			// draw original image
			CGContextSetBlendMode(context, .Normal)
			CGContextDrawImage(context, rect, self.CGImage)
			
			// tint image (loosing alpha) - the luminosity of the original image is preserved
			CGContextSetBlendMode(context, .Color)
			tintColor.setFill()
			CGContextFillRect(context, rect)
			
			// mask by alpha values of original image
			CGContextSetBlendMode(context, .DestinationIn)
			CGContextDrawImage(context, rect, self.CGImage)
		}
	}
	/**
	Tint Picto to color
	
	- parameter fillColor: UIColor
	
	- returns: UIImage
	*/
	public func tintPicto(fillColor: UIColor) -> UIImage {
		
		return modifiedImage { context, rect in
			// draw tint color
			CGContextSetBlendMode(context, .Normal)
			fillColor.setFill()
			CGContextFillRect(context, rect)
			
			// mask by alpha values of original image
			CGContextSetBlendMode(context, .DestinationIn)
			CGContextDrawImage(context, rect, self.CGImage)
		}
	}
	/**
	Modified Image Context, apply modification on image
	
	- parameter draw: (CGContext, CGRect) -> ())
	
	- returns: UIImage
	*/
	private func modifiedImage(@noescape draw: (CGContext, CGRect) -> ()) -> UIImage {
		
		// using scale correctly preserves retina images
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		let context: CGContext! = UIGraphicsGetCurrentContext()
		assert(context != nil)
		
		// correctly rotate image
		CGContextTranslateCTM(context, 0, size.height);
		CGContextScaleCTM(context, 1.0, -1.0);
		
		let rect = CGRectMake(0.0, 0.0, size.width, size.height)
		
		draw(context, rect)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image
	}
}