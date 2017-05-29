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
	@IBOutlet var retryButton: UIButton!
	
	var delegate: ErrorScreenDelegate?
	
	var error: SambaPlayerError {
		get { return _error }
		set {
			retryButton.isHidden = newValue.criticality != .recoverable
			textField.text = newValue.localizedDescription
			//iconView.image = newValue.icon
			
			_error = newValue
		}
	}
	
	private var _error = SambaPlayerError.unknown
	
	init(_ error: SambaPlayerError) {
		super.init(nibName: "ErrorScreen", bundle: Bundle(for: type(of: self)))
		loadViewIfNeeded()
		
		self.error = error
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@IBAction func retryHandler() {
		delegate?.onRetryTouch()
	}
}

protocol ErrorScreenDelegate {
	func onRetryTouch()
}
