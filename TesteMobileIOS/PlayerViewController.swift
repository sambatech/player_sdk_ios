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
        
        addEvents(sambaPlayer)
		
		sambaPlayer.frame = playerContainer.bounds
		
		playerContainer.addSubview(sambaPlayer)

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
            print("pause")
            self.progressLabel.text = "pause"
        }
        
        player.addEventListener("finish") { result in
            self.progressLabel.text = "finish"
        }
        
        player.addEventListener("progress") { result in
            //self.progressLabel.text = "progress"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
