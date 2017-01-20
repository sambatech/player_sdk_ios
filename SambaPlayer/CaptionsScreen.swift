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

	@IBOutlet var label: UILabel!
	
	private let _player: SambaPlayer
	private let _captionConfigs: [SambaMediaCaption]
	private var _captions = [Caption]()
	private var _captionsMap = [Int:[Caption]]()
	private var _parsed = false
	private var _currentCaption: Caption?
	
	private struct Caption {
		let index: Int, startTime: Float, endTime: Float, text: String
	}
	
	init(player: SambaPlayer, captions: [SambaMediaCaption]) {
		_player = player
		_captionConfigs = captions
		
		super.init(nibName: "CaptionsScreen", bundle: Bundle(for: type(of: self)))
		loadViewIfNeeded()
		
		_player.delegate = self
		view.isHidden = true
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		if let index = _captionConfigs.index(where: { $0.isDefault }) {
			changeCaption(index)
		}
	}
	
	func changeCaption(_ value: Int) {
		guard value != currentIndex,
			value < _captionConfigs.count else { return }
		
		currentIndex = value
		_currentCaption = nil
		
		// disable
		if _captionConfigs[value].url == "" {
			label.text = ""
			view.isHidden = true
			return
		}
		
		view.isHidden = false
		
		Helpers.requestURL(_captionConfigs[value].url, { (response: String?) in
			guard let response = response else { return }
			print("parsing...")
			self.parse(response)
		}) { (error, response) in
			print(error, response)
		}
	}
	
	// PLAYER DELEGATE
	
	func onLoad() {}
	func onStart() {}
	func onResume() {}
	func onPause() {}
	
	func onProgress() {
		guard _parsed else { return }
		
		let time = _player.currentTime
		
		guard let captions = _captionsMap[Int(time/60)] else { return }
		
		var captionNotFound = true
		
		// search for caption interval within time and consider only first match (in case of more than one)
		for caption in captions where caption.startTime >= time && caption.endTime <= time {
			captionNotFound = false
			
			if let current = _currentCaption, current.index != caption.index {
				label.text = caption.text
				_currentCaption = caption
			}
			break
		}
		
		if captionNotFound {
			label.text = ""
			_currentCaption = nil
		}
	}
	
	func onFinish() {}
	func onDestroy() {}
	func onError(_ error: SambaPlayerError) {}
	
	private func parse(_ captionsText: String) {
		_parsed = false
		
		var index = -1
		var startTime: Float = 0.0
		var endTime: Float = 0.0
		var text = ""
		var count = 0
		var time = [String]()
		var textLine = ""
		var offset = 0
		var m = 0
		var mLast = 0
		
		func appendCaption(mapAnyway: Bool = false) {
			// ignore first time or wrong index
			guard index != -1 else { return }
			
			m = Int(startTime/60)
			
			if mapAnyway {
				_captions.append(Caption(index: index, startTime: startTime, endTime: endTime, text: text))
				_captionsMap[mLast] = _captions
				return
			}
			
			if m != mLast {
				_captionsMap[mLast] = _captions
				_captions = [Caption]()
				mLast = m
			}
			
			_captions.append(Caption(index: index, startTime: startTime, endTime: endTime, text: text))
		}
		
		for match in Helpers.matchesForRegexInText(".+(!?[\\r\\n])", text: captionsText) {
			// caption index occurence
			if let r = match.range(of: "^\\d+(?=[\\r\\n]$)", options: .regularExpression) {
				appendCaption()
				
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
				time = Helpers.matchesForRegexInText("\\d+", text: match)
				startTime = extractTime(time)
				endTime = extractTime(time, offset: 4)
				print(startTime, endTime)
			default:
				textLine = match.replacingOccurrences(of: "[\\r\\n]", with: " ", options: .regularExpression)
				text += textLine == " " ? "" : textLine
				print(text)
			}
			
			count += 1
		}
		
		appendCaption(mapAnyway: true)
		
		_parsed = true
	}
	
	private func extractTime(_ time: [String], offset: Int = 0) -> Float {
		guard time.count > 0 && (time.count + offset)%4 == 0 else { return 0.0 }
		
		let h = (Int(time[offset + 0]) ?? 0)*3600
		let m = (Int(time[offset + 1]) ?? 0)*60
		let s = (Int(time[offset + 2]) ?? 0)
		let ms = (Int(time[offset + 3]) ?? 0)
		
		return Float(h + m + s) + Float(ms)/1000.0
	}
}
