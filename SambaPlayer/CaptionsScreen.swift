//
//  ErrorScreenViewController.swift
//  SambaPlayer
//
//  Created by Leandro Zanol on 11/22/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import Foundation

class CaptionsScreen : UIViewController, SambaPlayerDelegate {
	
	public private(set) var currentIndex: Int = -1

	@IBOutlet var textField: UILabel!
	
	private let _player: SambaPlayer
	private let _captions: [SambaMediaCaption]
	
	init(player: SambaPlayer, captions: [SambaMediaCaption]) {
		_player = player
		_captions = captions
		
		super.init(nibName: "CaptionsScreen", bundle: Bundle(for: type(of: self)))
		
		_player.delegate = self
		view.isHidden = true
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		if let index = _captions.index(where: { $0.isDefault }) {
			changeCaption(index)
		}
	}
	
	func changeCaption(_ value: Int) {
		guard value != currentIndex,
			value < _captions.count else { return }
		
		currentIndex = value
		
		// disable
		if _captions[value].url == "" {
			textField.text = ""
			view.isHidden = true
			return
		}
		
		view.isHidden = false
		
		Helpers.requestURL(_captions[value].url, { (response: String?) in
			guard let response = response else { return }
			self.parse(response)
		}) { (error, response) in
			print(error, response)
		}
	}
	
	func parse(cations: String) {
		var captions = [Caption]()
		var index = -1
		var startTime: Float = 0.0
		var endTime: Float = 0.0
		var text = ""
		var count = 0
		var time = [String]()
		var offset = 0
		
		for match in Helpers.matchesForRegexInText(".+(!?[\\r\\n])", text: captions) {
			// if caption index occurence
			if let r = match.range(of: "^\\d+(?=[\\r\\n]$)", options: .regularExpression) {
				captions.append(Caption(index: index, startTime: startTime, endTime: endTime, text: text))
				index = Int(match[r]) ?? -1
				startTime = 0.0
				endTime = 0.0
				text = ""
				count = 1
				print(index)
				continue
			}
			
			switch count {
			case 1:
				time = matchesForRegexInText("\\d+", text: match)
				startTime = extractTime(time)
				endTime = extractTime(time, offset: 4)
				
				print(startTime, endTime)
			default:
				text += match.replacingOccurrences(of: "[\\r\\n]", with: " ", options: .regularExpression)
				print(text)
			}
			
			count += 1
		}
	}
	
	// PLAYER DELEGATE
	
	func onLoad() {}
	func onStart() {}
	func onResume() {}
	func onPause() {}
	
	func onProgress() {
		
	}
	
	func onFinish() {}
	func onDestroy() {}
	func onError(_ error: SambaPlayerError) {}
	
	func extractTime(_ time: [String], offset: Int = 0) -> Float {
		guard time.count > 0 && (time.count + offset)%4 == 0 else { return 0.0 }
		
		let h = (Int(time[offset + 0]) ?? 0)*3600
		let m = (Int(time[offset + 1]) ?? 0)*60
		let s = (Int(time[offset + 2]) ?? 0)
		let ms = (Int(time[offset + 3]) ?? 0)
		
		return Float(h + m + s) + Float(ms)/1000.0
	}
}

struct Caption {
	let index: Int, startTime: Float, endTime: Float, text: String
}
