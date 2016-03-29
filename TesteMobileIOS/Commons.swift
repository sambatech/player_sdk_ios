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

class CallbackContainer {
	let callback: () -> Void
	
	init(callback: () -> Void) {
		self.callback = callback
	}
	
	@objc func callCallback() {
		callback()
	}
}

extension UIControl {
	
	public func addCallback(callback: () -> Void, forControlEvents controlEvents: UIControlEvents) -> UnsafePointer<Void> {
		let callbackContainer = CallbackContainer(callback: callback)
		let key = unsafeAddressOf(callbackContainer)
		objc_setAssociatedObject(self, key, callbackContainer, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		addTarget(callbackContainer, action: "callCallback", forControlEvents: controlEvents)
		return key
	}
	
	public func removeCallbackForKey(key: UnsafePointer<Void>) {
		if let callbackContainer = objc_getAssociatedObject(self, key) as? CallbackContainer {
			removeTarget(callbackContainer, action: "callCallback", forControlEvents: .AllEvents)
			objc_setAssociatedObject(self, key, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}
