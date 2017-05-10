//
//  ErrorScreenViewController.swift
//  SambaPlayer
//
//  Created by Leandro Zanol on 11/22/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import Foundation

class ErrorScreen : UIViewController {
	
	@IBOutlet var textField: UILabel!
	@IBOutlet var iconView: UIImageView!
	@IBOutlet var retryButton: UIImageView!
	
	var error: SambaPlayerError {
		didSet {
			retryButton.isHidden = error.criticality != .recoverable
			textField.text = error.localizedDescription
			//iconView.image = error.icon
		}
	}
	
	init(_ error: SambaPlayerError) {
		self.error = error
		
		super.init(nibName: "ErrorScreen", bundle: Bundle(for: type(of: self)))
		loadViewIfNeeded()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
