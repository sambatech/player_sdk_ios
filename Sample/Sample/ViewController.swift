//
//  ViewController.swift
//  TesteMobileIOS
//
//  Created by Thiago Miranda on 25/02/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import UIKit
import Alamofire

class PlayerViewController: UIViewController {
	
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
		self.sambaPlayer = SambaPlayer()
		
		addEvents(sambaPlayer)
		
		sambaPlayer.view.frame = playerContainer.bounds
		
		addChildViewController(sambaPlayer)
		playerContainer.addSubview(sambaPlayer.view)
		
		sambaPlayer.media = media
		sambaPlayer.play()
	}
	
	private func addEvents(player: SambaPlayer) {
		player.addEventListener("load") { result in
			self.progressLabel.text = "load"
		}
		
		player.addEventListener("play") { result in
			self.progressLabel.text = "play"
		}
		
		player.addEventListener("pause") { result in
			self.progressLabel.text = "pause"
		}
		
		player.addEventListener("finish") { result in
			self.progressLabel.text = "finish"
		}
		
		player.addEventListener("progress") { result in
			self.timeField.text = self.secondsToHoursMinutesSeconds(self.sambaPlayer.currentTime)
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
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
