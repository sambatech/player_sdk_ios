//
//  SambaPlayer.swift
//
//
//  Created by Leandro Zanol on 3/9/16.
//
//

import Foundation
import UIKit

public class SambaPlayer {
	
	public var _player: AnyObject?
	public var media: SambaMedia? {
		didSet {
			if media != nil { return }
			destroy()
			//createThumb()
		}
	}
	
	private let container: UIView
	
	public init(container: UIView) {
		self.container = container
	}
	
	public func play() {
		if _player == nil {
			create()
			return
		}
		
		//_player.play()
	}
	
	public func create() {
		/*let videoURL = NSURL(string:  "http://gbbrfd.sambavideos.sambatech.com/account/37/2/2015-11-05/video/cb7a5d7441741d8bcb29abc6521d9a85/marina_360p.mp4")!
		let playerVC = MobilePlayerViewController(contentURL: videoURL,
		config: MobilePlayerConfig(fileURL: NSBundle.mainBundle().URLForResource("PlayerSkin", withExtension: "json")!))
		
		playerVC.title = "Teste Mobile"
		playerVC.activityItems = [videoURL]
		presentMoviePlayerViewControllerAnimated(playerVC)
		
		self.container.addSubview(playerVC.view)*/
	}
	
	public func destroy() {
		
	}
}