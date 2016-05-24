//
//  ViewController.swift
//  TesteMobileIOS
//
//  Created by Thiago Miranda on 25/02/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import UIKit
import Alamofire

class PlayerViewController: UIViewController, SambaPlayerDelegate {
	
	@IBOutlet weak var playerContainer: UIView!
	@IBOutlet weak var progressLabel: UILabel!
	@IBOutlet weak var timeField: UITextField!
	
	var sambaPlayer:SambaPlayer!
	var mediaInfo: MediaInfo?
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		guard let m = self.mediaInfo else {
			print("Error: No media info found!")
			return
		}
		
		SambaApi().requestMedia(SambaMediaRequest(
			projectHash: m.projectHash,
			mediaId: m.mediaId
			),
			callback: { media in
				guard let media = media else { return }
				self.initPlayer(media)
		})
	}
	
	private func initPlayer(media: SambaMedia) {
		self.sambaPlayer = SambaPlayer(self, parentView: playerContainer)

		sambaPlayer.delegate = self
		sambaPlayer.media = media
		sambaPlayer.play()
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
	
	//MARK: actions
	@IBAction func playAction(sender: AnyObject) {
		self.sambaPlayer.play()
	}
	
	@IBAction func pauseAction(sender: AnyObject) {
		self.sambaPlayer.pause()
	}
	
	//MARK: utils
	func secondsToHoursMinutesSeconds (seconds : Int) -> (String) {
		let hours = Int(seconds/3600) > 9 ? String(Int(seconds/3600)) : "0" + String(Int(seconds/3600))
		let minutes = Int((seconds % 3600) / 60) > 9 ? String(Int((seconds % 3600) / 60)) : "0" + String(Int((seconds % 3600) / 60))
		let second = Int((seconds % 3600) % 60) > 9 ? String(Int((seconds % 3600) % 60)) : "0" + String(Int((seconds % 3600) % 60))
		return hours + ":" + minutes + ":" + second
	}
}
