//
//  Tracking.swift
//  Sample
//
//  Created by Thiago Miranda on 06/06/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import Foundation

class Tracking: SambaPlayerDelegate {
	private var _player: SambaPlayer
	private var _media: SambaMedia
	private var _sttm = STTM()
	
	init(_ player: SambaPlayer) {
		_player = player
		_media = player.media
		_player.delegate = self
	}
	
	func onLoad() {
		print("onload")
	}
	
	func onStart() {
		print("onstart")
	}
	
	func onResume() {
		print("onresume")
	}
	
	func onPause() {
		print("onpause")
	}
	
	func onProgress() {
		print("onprogress")
	}
	
	func onFinish() {
		print("onfinish")
	}
	
	func onDestroy() {
		_sttm.destroy()
	}
}

class STTM {
	private var _timer: NSTimer?
	private var _targets = [String]()
	private var _progresses = NSMutableOrderedSet()
	private var _trackedRetentions = Set<Int>()
	
	init() {
		_timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(timerHandler), userInfo: nil, repeats: true)
	}
	
	func trackStart() {
		_targets.append("play")
	}
	
	func trackProgress(time: Float, duration: Float) {
		var p = Int(100*time/duration)
		
		if p > 99 {
			p = 99
		}
		
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
		_targets.append("complete")
	}
	
	func destroy() {
		_timer?.invalidate()
	}
	
	private func collectProgress() {
		if _progresses.count == 0 { return }
		
		_progresses.sortUsingComparator { $0.localizedCaseInsensitiveCompare($1 as! String) }
		_targets.append((_progresses.array as! [String]).joinWithSeparator(","))
		_progresses.removeAllObjects()
	}
	
	@objc private func timerHandler() {
		if _targets.isEmpty { return }
		
		/*new UrlTracker().execute(String.format("%s?sttmm=%s&sttmk=%s&sttms=%s&sttmu=123&sttmw=%s",
			media.sttmUrl, TextUtils.join(",", targets), media.sttmKey, media.sessionId,
			String.format("pid:%s/cat:%s/mid:%s", media.projectId, media.categoryId, media.id)));*/
		
		_targets.removeAll()
	}
}
