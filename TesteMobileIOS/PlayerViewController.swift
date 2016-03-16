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
        
        addEvents(sambaPlayer)

		
		playerContainer.addSubview(sambaPlayer)

		sambaPlayer.media = media
		sambaPlayer.play()
    }
    
    private func addEvents(player: SambaPlayer) {
        player.addEventListener("load") { result in
            print("carreguei \(result)")
            let p = result.object as! SambaPlayer
            print(p.media.title)
        }
        
        player.addEventListener("play") { result in
            print("playei \(result)")
            let p = result.object as! SambaPlayer
            print(p.media.title)
        }
        
        player.addEventListener("pause") { result in
            print("pausei \(result)")
            let p = result.object as! SambaPlayer
            print(p.media.title)
        }
        
        player.addEventListener("finish") { result in
            print("finishei \(result)")
            let p = result.object as! SambaPlayer
            print(p.media.title)
        }
        
        player.addEventListener("progress") { result in
            print("progressei \(result)")
            let p = result.object as! SambaPlayer
            print(p.currentTime)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
