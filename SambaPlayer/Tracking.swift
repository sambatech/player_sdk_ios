//
//  Tracking.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation

class Tracking: SambaPlayerDelegate {
	private var _player: SambaPlayer
	private var _sttm: STTM?
	
	/**
	Default initializer
	
	- Parameters:
		- player:SambaPlayer
	**/
	init(_ player: SambaPlayer) {
		_player = player
		
		// media data cannot be user provided
		guard let media = player.media as? SambaMediaConfig else { return }
		
		_sttm = STTM(media)
		player.delegate = self
	}
	
	func onStart() {
		_sttm?.trackStart()
	}
	
	func onProgress() {
		_sttm?.trackProgress(_player.currentTime, _player.duration)
	}
	
	func onFinish() {
		_sttm?.trackComplete()
	}
	
	func onDestroy() {
		_sttm?.destroy()
	}
	
	func onLoad() {}
	func onResume() {}
	func onPause() {}
}

class STTM {
	private var _media: SambaMediaConfig
	private var _timer: NSTimer?
	private var _targets = [String]()
	private var _progresses = NSMutableOrderedSet()
	private var _trackedRetentions = Set<Int>()
	
	init(_ media: SambaMediaConfig) {
		_media = media
		_timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(timerHandler), userInfo: nil, repeats: true)
	}
	
	func trackStart() {
		#if DEBUG
		print("start")
		#endif
		
		_targets.append("play")
	}
	
	func trackProgress(time: Float, _ duration: Float) {
		guard duration > 0 else { return }
		
		var p = Int(100*time/duration)
		
		if p > 99 {
			p = 99
		}
		
		#if DEBUG
		print("progress", p)
		#endif
		
		_progresses.addObject(String(format: "p%02d", p))
		
		if !_trackedRetentions.contains(p) {
			_progresses.addObject(String(format: "r%02d", p))
		}
		
		_trackedRetentions.insert(p)
		
		if _progresses.count >= 5 {
			collectProgress()
		}
	}
	
	func trackComplete() {
		#if DEBUG
		print("complete")
		#endif
		
		_targets.append("complete")
	}
	
	func destroy() {
		#if DEBUG
		print("destroy")
		#endif
		
		_timer?.invalidate()
	}
	
	private func collectProgress() {
		guard _progresses.count > 0 else { return }
		
		#if DEBUG
		print("collect", _progresses.count)
		#endif
		
		_progresses.sortUsingComparator { $0.localizedCaseInsensitiveCompare($1 as! String) }
		_targets.append((_progresses.array as! [String]).joinWithSeparator(","))
		_progresses.removeAllObjects()
	}
	
	@objc private func timerHandler() {
		guard !_targets.isEmpty else { return }
		
		let url = "\(_media.sttmUrl)?sttmm=\(_targets.joinWithSeparator(","))&sttmk=\(_media.sttmKey)&sttms=\(_media.sessionId)&sttmu=123&sttmw=pid:\(_media.projectId)/cat:\(_media.categoryId)/mid:\(_media.id)"
		
		#if DEBUG
		print("send", url)
		#endif
		
		Helpers.requestURL(url)
		
		_targets.removeAll()
	}
}
