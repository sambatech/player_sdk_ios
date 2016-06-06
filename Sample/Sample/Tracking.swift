//
//  Tracking.swift
//  Sample
//
//  Created by Thiago Miranda on 06/06/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import Foundation

public class Tracking: SambaPlayerDelegate {
	private var _player:SambaPlayer
	private var _media:SambaMedia
	
	init(player:SambaPlayer, media:SambaMedia){
		self._player = player
		self._media = media
		
		self._player.delegate = self
	}
	
	public func onLoad() {
		print("onload")
	}
	
	public func onStart() {
		print("onstart")
	}
	
	public func onResume() {
		print("onresume")
	}
	
	public func onPause() {
		print("onpause")
	}
	
	public func onProgress() {
		print("onprogress")
	}
	
	public func onFinish() {
		print("onfinish")
	}
	
}