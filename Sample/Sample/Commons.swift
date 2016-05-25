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
	static let settings = NSDictionary.init(contentsOfFile: NSBundle.mainBundle().pathForResource("Settings", ofType: "plist")!)! as! [String:String]
	
	static func matchesForRegexInText(regex: String!, text: String!) -> [String] {
		do {
			let regex = try NSRegularExpression(pattern: regex, options: [])
			let nsString = text as NSString
			let results = regex.matchesInString(text,
				options: [], range: NSMakeRange(0, nsString.length))
			
			return results.map { nsString.substringWithRange($0.range) }
		}
		catch let error as NSError {
			print("Error: Invalid regex: \(error.localizedDescription)")
		}
		catch {
			print("Error: Some other regex error!")
		}
		
		return []
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
