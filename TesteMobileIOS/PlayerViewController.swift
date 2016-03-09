//
//  ViewController.swift
//  TesteMobileIOS
//
//  Created by Thiago Miranda on 25/02/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import UIKit
import MobilePlayer
import Alamofire

class PlayerViewController: UIViewController {

    @IBOutlet weak var playerContainer: UIView!
	
	var mediaInfo: MediaInfo?
	
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

		guard let m = self.mediaInfo else {
			print("Error: No media info found!")
			return
		}
		
		let sambaApi = SambaApi()
		
		sambaApi.requestMedia(SambaMediaRequest(
			projectHash: m.projectHash,
			mediaId: m.mediaId
		),
		callback: { media in
			self.playMedia(media)
		})
	}
	
	private func playMedia(media: SambaMedia) {
		let sambaPlayer = SambaPlayer(container: playerContainer)
		
		sambaPlayer.media = media
		sambaPlayer.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
