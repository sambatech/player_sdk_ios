//
//  ViewController.swift
//  TesteMobileIOS
//
//  Created by Thiago Miranda on 25/02/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import UIKit
import MobilePlayer

class PlayerViewController: UIViewController {

    @IBOutlet weak var playerContainer: UIView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
		
        let videoURL = NSURL(string:  "http://gbbrfd.sambavideos.sambatech.com/account/37/2/2015-11-05/video/cb7a5d7441741d8bcb29abc6521d9a85/marina_360p.mp4")!
		let playerVC = MobilePlayerViewController(contentURL: videoURL,
			config: MobilePlayerConfig(fileURL: NSBundle.mainBundle().URLForResource("PlayerSkin", withExtension: "json")!))
			
        playerVC.title = "Teste Mobile"
        playerVC.activityItems = [videoURL]
        presentMoviePlayerViewControllerAnimated(playerVC)
        
        self.playerContainer.addSubview(playerVC.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
