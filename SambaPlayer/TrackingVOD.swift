//
//  Tracking.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation

class TrackingVOD : NSObject, Tracking, SambaPlayerDelegate {
	private weak var _player: SambaPlayer?
	private var _sttm: STTM?
	
    
    func onLoadPlugin(with player: SambaPlayer) {
        _player = player
        
        player.delegate = self
    }
    
    func onDestroyPlugin() {
        _player?.unsubscribeDelegate(self)
        if _sttm != nil {
            _sttm?.destroy()
            _sttm = nil
        }
    }
    
	
	// PLAYER DELEGATE
	
	func onStart() {
		// media data must come from API
		// do not track live
		guard let media = _player?.media as? SambaMediaConfig,
			!media.isLive
			else { return }
		
		// reset sttm on every new start
		_sttm = STTM(media)
		_sttm?.trackStart()
	}
	
	func onProgress() {
        _sttm?.trackProgress(_player?.currentTime ?? 0, _player?.duration ?? 0)
	}
	
	func onFinish() {
		_sttm?.trackComplete()
	}
	
	func onReset() {
		onDestroy()
	}
	
	func onDestroy() {
		_sttm?.destroy()
	}
}

class STTM {
	private var _media: SambaMediaConfig
	private var _timer: Timer?
	private var _targets = [String]()
	private var _progresses = NSMutableOrderedSet()
	private var _trackedRetentions = Set<Int>()
	
	init(_ media: SambaMediaConfig) {
		_media = media
		_timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(timerHandler), userInfo: nil, repeats: true)
	}
	
	func trackStart() {
		#if DEBUG
		print("start")
		#endif
		
		_targets.append("play")
	}
	
	func trackProgress(_ time: Float, _ duration: Float) {
		guard duration > 0 else { return }
		
		var p = Int(100*time/duration)
		
		if p > 99 {
			p = 99
		}
		
		#if DEBUG
		print("progress", p)
		#endif
		
		_progresses.add(String(format: "p%02d", p))
		
		if !_trackedRetentions.contains(p) {
			_progresses.add(String(format: "r%02d", p))
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
        if _timer != nil {
            _timer?.invalidate()
            _timer = nil
        }
        _targets.removeAll()
        _progresses.removeAllObjects()
        _trackedRetentions.removeAll()
	}
	
	private func collectProgress() {
		guard _progresses.count > 0 else { return }
		
		#if DEBUG
		print("collect", _progresses.count)
		#endif
		
		_progresses.sort(comparator: { ($0 as AnyObject).localizedCaseInsensitiveCompare($1 as! String) })
		_targets.append((_progresses.array as! [String]).joined(separator: ","))
		_progresses.removeAllObjects()
	}
	
	@objc private func timerHandler() {
		guard !_targets.isEmpty else { return }
		
		let url = "\(_media.sttmUrl)?sttmm=\(_targets.joined(separator: ","))&sttmk=\(_media.sttmKey)&sttms=\(_media.sessionId)&sttmu=123&sttmw=pid:\(_media.projectId)/cat:\(_media.categoryId)/mid:\(_media.id)"
		
		#if DEBUG
		print("send", url)
		#endif
		
        if Helpers.isConnectedToInternet() {
            Helpers.requestURL(url)
        }
		
		_targets.removeAll()
	}
}
