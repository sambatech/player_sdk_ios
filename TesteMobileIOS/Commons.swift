//
//  Commons.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/8/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation

class Commons {
	static let dict = NSDictionary.init(contentsOfFile: NSBundle.mainBundle().pathForResource("Settings", ofType: "plist")!)! as! [String:String]
}