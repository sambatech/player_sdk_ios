//
//  ErrorScreenViewController.swift
//  SambaPlayer
//
//  Created by Leandro Zanol on 11/22/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import Foundation

class ErrorScreen : OverlayScreen {
	
	init(_ error: SambaPlayerError) {
		super.init(name: "ErrorScreen")
		
		textField.text = error.localizedDescription
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
