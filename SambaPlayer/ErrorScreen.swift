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
	
	init(_ error: SambaPlayerError) {
		super.init(nibName: "ErrorScreen", bundle: Bundle(for: type(of: self)))
		loadViewIfNeeded()
		
		textField.text = error.localizedDescription
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
