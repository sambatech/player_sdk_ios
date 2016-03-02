//
//  ViewController.swift
//  TesteMobileIOS
//
//  Created by Thiago Miranda on 25/02/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import UIKit
//import MobilePlayer
import Alamofire

class ViewController: UIViewController {

    @IBOutlet weak var playerContainer: UIView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print("appear")
        /*let videoURL = NSURL(string:  "http://gbbrfd.sambavideos.sambatech.com/account/37/2/2015-11-05/video/cb7a5d7441741d8bcb29abc6521d9a85/marina_360p.mp4")!
        
        let playerVC = MobilePlayerViewController(contentURL: videoURL)
        
        playerVC.title = "Teste Mobile"
        playerVC.activityItems = [videoURL]
        presentMoviePlayerViewControllerAnimated(playerVC)
        
        self.playerContainer.addSubview(playerVC.view)*/
        
        Alamofire.request(.GET, "http://api.sambavideos.sambatech.com/v1/medias?access_token=079cc2f1-4733-4c92-a7b5-7e1640698caa&pid=4460&published=true")
            .responseJSON { response in
                if let json = response.result.value {
					var mediaList = [SambaMedia]()
					
					for mediaNode in json {
						let media = SambaMedia()
						media.title = json[i]["title"] as? String ?? ""
						mediaList.append(media)
					}
					
					print(mediaList)
                }
                else  {
                    print("Invalid JSON format!")
                }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print("load")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

class SambaMedia {
	var title:String = ""
}
