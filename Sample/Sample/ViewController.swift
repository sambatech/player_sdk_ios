//
//  ViewController.swift
//  Sample
//
//  Created by Leandro Zanol on 5/18/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	@IBOutlet var videoContainer: UIView!
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		let gmf = GMFPlayerViewController()
		
		gmf.loadStreamWithURL(NSURL(string: "http://gbbrpvbps-sambavideos.akamaized.net/account/37/2/2015-11-05/video/cb7a5d7441741d8bcb29abc6521d9a85/marina_360p.mp4"))
		gmf.videoTitle = "My Video!!"

		addChildViewController(gmf)
		gmf.didMoveToParentViewController(self)
		gmf.view.frame = videoContainer.frame
		videoContainer.addSubview(gmf.view)
		videoContainer.setNeedsDisplay()
		
		gmf.play()

		//presentViewController(gmf, animated: true, completion: nil)
	}
}

