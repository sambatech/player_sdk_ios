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
			guard let _ = media else { return }
			self.initPlayer(media!)
		})

	}
	
	private func initPlayer(media: SambaMedia) {
		let sambaPlayer = SambaPlayer()
		
		sambaPlayer.frame = CGRect(x: 30, y: 25, width: 360, height: 200)
		playerContainer.addSubview(sambaPlayer)

		sambaPlayer.media = media
		sambaPlayer.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
