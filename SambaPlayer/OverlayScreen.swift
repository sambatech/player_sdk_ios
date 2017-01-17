//
//  ErrorScreenViewController.swift
//  SambaPlayer
//
//  Created by Leandro Zanol on 11/22/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import Foundation

class OverlayScreen : UIViewController {
	
	@IBOutlet var textField: UILabel!
	
	// default constructor
	init(name: String = "OverlayScreen") {
		super.init(nibName: nil, bundle: nil)
		
		guard let view = Bundle(for: type(of: self)).loadNibNamed(name, owner: self, options: nil)?.first as? UIView else {
			fatalError("\(type(of: self)) error: Couldn't load view.")
		}
		
		self.view = view
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
