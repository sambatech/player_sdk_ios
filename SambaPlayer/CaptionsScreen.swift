//
//  ErrorScreenViewController.swift
//  SambaPlayer
//
//  Created by Leandro Zanol on 11/22/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import Foundation

class CaptionsScreen : OverlayScreen {
	
	init(media: SambaMediaConfig) {
		super.init()
		
		//if let captions = media.captions
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func changeText(_ text: String) {
		textField.text = text
	}
}
