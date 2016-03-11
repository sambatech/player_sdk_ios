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
		
		SambaApi().requestMedia(SambaMediaRequest(
			projectHash: m.projectHash,
			mediaId: m.mediaId
		),
		callback: { media in
			guard let _ = media else { return }
			self.playMedia(media!)
		})
        
        let videoURL = NSURL(string: "http://test.d.sambavideos.sambatech.com/account/100209/1/2012-05-04/video/4b3b76a5d1698cd185bc2d84db3a11a2/Rango_-_Trailer__HD_1080p_.mp4")!
        let playerVC = MobilePlayerViewController(contentURL: videoURL)
        playerVC.title = "Vanilla Player - Trailer"
        playerVC.activityItems = [videoURL] // Check the documentation for more information.
        playerVC.view.frame = CGRect(x: 30, y: 25, width: playerContainer.frame.width, height: playerContainer.frame.height)
        //presentMoviePlayerViewControllerAnimated(playerVC)
        
        playerContainer.addSubview(playerVC.view)
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
