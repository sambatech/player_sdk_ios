//
//  ViewController.swift
//  TesteMobileIOS
//
//  Created by Thiago Miranda on 25/02/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import UIKit
import SambaPlayer

class PlayerViewController: UIViewController, SambaPlayerDelegate {
	
	@IBOutlet weak var playerContainer: UIView!
	@IBOutlet weak var progressLabel: UILabel!
	@IBOutlet weak var timeField: UITextField!
	
	var sambaPlayer: SambaPlayer!
	var mediaInfo: MediaInfo?
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		guard let m = self.mediaInfo else {
			print("Error: No media info found!")
			return
		}
		
		guard sambaPlayer == nil else { return }
		
		let callback = { (media: SambaMedia?) in
			guard let media = media else { return }
			self.initPlayer(media)
		}
		
		if (m.mediaId != nil) {
			SambaApi().requestMedia(SambaMediaRequest(
				projectHash: m.projectHash,
				mediaId: m.mediaId!), callback: callback)
		}
		else {
			SambaApi().requestMedia(SambaMediaRequest(
				projectHash: m.projectHash,
				streamUrl: m.mediaURL!, isLiveAudio: m.isLiveAudio), callback: callback)
		}
	}
	
	private func initPlayer(media: SambaMedia) {
		// if ad injection
		if let url = mediaInfo?.mediaAd {
			media.adUrl = url
		}

		if media.isAudio {
			var frame = self.playerContainer.frame
			frame.size.height = media.isLive ? 100 : 50
			self.playerContainer.frame = frame
		}
		
		self.sambaPlayer = SambaPlayer(parentViewController: self, andParentView: self.playerContainer)
		self.sambaPlayer.delegate = self
		self.sambaPlayer.media = media
		self.sambaPlayer.play()
	}
	
	func onLoad() {
		self.progressLabel.text = "load"
	}
	
	func onStart() {
		self.progressLabel.text = "start"
	}
	
	func onResume() {
		self.progressLabel.text = "resume"
	}
	
	func onPause() {
		self.progressLabel.text = "pause"
	}
	
	func onProgress() {
		self.timeField.text = self.secondsToHoursMinutesSeconds(self.sambaPlayer.currentTime)
	}
	
	func onFinish() {
		self.progressLabel.text = "finish"
	}
	
	func onDestroy() {}
	
	//MARK: actions
	@IBAction func playAction(sender: AnyObject) {
		self.sambaPlayer.play()
	}
	
	@IBAction func pauseAction(sender: AnyObject) {
		self.sambaPlayer.pause()
	}
	
	//MARK: utils
	func secondsToHoursMinutesSeconds (seconds : Float) -> (String) {
		let hours = Int(seconds/3600) > 9 ? String(Int(seconds/3600)) : "0" + String(Int(seconds/3600))
		let minutes = Int((seconds % 3600) / 60) > 9 ? String(Int((seconds % 3600) / 60)) : "0" + String(Int((seconds % 3600) / 60))
		let second = Int((seconds % 3600) % 60) > 9 ? String(Int((seconds % 3600) % 60)) : "0" + String(Int((seconds % 3600) % 60))
		return hours + ":" + minutes + ":" + second
	}
}
