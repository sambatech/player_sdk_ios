//
//  ErrorScreenViewController.swift
//  SambaPlayer
//
//  Created by Leandro Zanol on 11/22/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import Foundation

class ErrorScreenViewController : UIViewController {
	
	@IBOutlet var label: UILabel!
	
	init(_ error: SambaPlayerError) {
		super.init(nibName: nil, bundle: nil)
		
		guard let view = Bundle(for: type(of: self)).loadNibNamed("ErrorScreen", owner: self, options: nil)?.first as? UIView else {
			print("\(type(of: self)) error: Couldn't load view.")
			return
		}
		
		self.view = view
		label.text = error.localizedDescription
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
