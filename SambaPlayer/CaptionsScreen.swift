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
	private var _captionsRequest = [SambaMediaCaption]()
	private var _captionsMap = [Int:[Caption]]()
	private var _parsed = false
	private var _currentCaption: Caption?
	
	public var hasCaptions: Bool {
		return _captionsRequest.count > 0
	}
	
	private struct Caption {
		let index: Int, startTime: Float, endTime: Float, text: String
	}
	
	init(player: SambaPlayer) {
		_player = player
		
		super.init(nibName: "CaptionsScreen", bundle: Bundle(for: type(of: self)))
		loadViewIfNeeded()
		
		_player.delegate = self
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		load()
	}
	
	func changeCaption(_ value: Int) {
		guard value != currentIndex,
			value < _captionsRequest.count else { return }
        
		reset(value)
		
		// disable
		if _captionsRequest[value].url == "" {
			view.isHidden = true
			return
		}
		
		view.isHidden = false
        
        if  _player.media.isOffline,
            let captionURL = URL(string: _captionsRequest[value].url),
            let response = try? String(contentsOf: captionURL) {
            self.parse(response)
        } else {
            Helpers.requestURL(_captionsRequest[value].url, { (response: String?) in
                guard let response = response else { return }
                #if DEBUG
                print("parsing captions...")
                #endif
                self.parse(response)
            }) { (error, response) in
                print(error ?? "error undefined", response ?? "response undefined")
            }
        }
	}
	
	// PLAYER DELEGATE
	
	func onLoad() {
		guard isViewLoaded else { return }
		load()
	}
	
	func onProgress() {
		guard _parsed else { return }
		
		let time = _player.currentTime
		
		guard let captions = _captionsMap[Int(time/60)] else { return }
		
		var captionNotFound = true
		
		// search for caption interval within time and consider only first match (in case of more than one)
		for caption in captions where time >= caption.startTime && time <= caption.endTime {
			captionNotFound = false
			
			if _currentCaption == nil || _currentCaption?.index != caption.index {
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
	
	func onReset() {
		reset()
		_captionsRequest = [SambaMediaCaption]()
	}
	
	private func load() {
        let media = _player.media
		
		guard let captions = media.captions,
			captions.count > 0 else { return }
		
		let config = media.captionsConfig
		let index: Int
		
		_captionsRequest = captions
		
		if let lang = config.language?.lowercased().replacingOccurrences(of: "_", with: "-"),
			let indexConfig = _captionsRequest.index(where: { $0.language.lowercased().replacingOccurrences(of: "_", with: "-") == lang }) {
			index = indexConfig
		}
		else if let indexApi = _captionsRequest.index(where: { $0.isDefault }) {
			index = indexApi
		}
		else {
			index = 0
		}
		
		label.textColor = UIColor(config.color)
		label.font = label.font.withSize(CGFloat(config.size))
		
		changeCaption(index)
	}
	
	private func reset(_ defaultIndex: Int = -1) {
		_parsed = false
		_currentCaption = nil
		label.text = ""
		currentIndex = defaultIndex
	}
	
	private func parse(_ captionsText: String) {
		_parsed = false
		_captionsMap = [Int:[Caption]]()
		
		var captions = [Caption]()
		var index = -1
		var startTime: Float = 0.0
		var endTime: Float = 0.0
		var text = ""
		var count = 0
		var time = [String]()
		var textLine = ""
		var m = 0
		var mLast = 0
		
		func appendCaption(mapAnyway: Bool = false) {
			// ignore first time or wrong index
			guard index != -1 else { return }
			
			m = Int(startTime/60)
			
			if mapAnyway {
				captions.append(Caption(index: index, startTime: startTime, endTime: endTime, text: text))
				_captionsMap[mLast] = captions
				return
			}
			
			if m != mLast {
				_captionsMap[mLast] = captions
				captions = [Caption]()
				mLast = m
			}
			
			captions.append(Caption(index: index, startTime: startTime, endTime: endTime, text: text))
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
				#if DEBUG
					print(index)
				#endif
				continue
			}
			
			switch count {
			case 1:
				time = Helpers.matchesForRegexInText("\\d+", text: match)
				startTime = extractTime(time)
				endTime = extractTime(time, offset: 4)
				#if DEBUG
					print(startTime, endTime)
				#endif
			default:
				textLine = match.replacingOccurrences(of: "[\\r\\n]", with: " ", options: .regularExpression)
				text += textLine.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
				#if DEBUG
					print(text)
				#endif
			}
			
			count += 1
		}
		
		appendCaption(mapAnyway: true)
		
		_parsed = true
	}
	
	private func extractTime(_ time: [String], offset: Int = 0) -> Float {
		guard time.count > 0 && (time.count + offset)%4 == 0 else { return 0.0 }
		
		let h = (Int(time[offset]) ?? 0)*3600
		let m = (Int(time[offset + 1]) ?? 0)*60
		let s = (Int(time[offset + 2]) ?? 0)
		let ms = (Int(time[offset + 3]) ?? 0)
		
		return Float(h + m + s) + Float(ms)/1000.0
	}
}
