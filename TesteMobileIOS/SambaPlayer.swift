//
//  SambaPlayer.swift
//
//
//  Created by Leandro Zanol on 3/9/16.
//
//

import Foundation
import UIKit
import MobilePlayer

public class SambaPlayer {
	
	public var _player: AnyObject?
	public var media: SambaMedia = SambaMedia() {
		didSet {
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
			try! create()
			return
		}
		
		//_player.play()
	}
	
	public func create() throws {
		var urlWrapped = media.url
		
		if let outputs = media.outputs where outputs.count > 0 {
			urlWrapped = outputs[0].url
		}
		
		guard let url = urlWrapped else {
			throw SambaPlayerError.NoUrlFound
		}
		
		let videoURL = NSURL(string: url)!
		let player = MobilePlayerViewController(contentURL: videoURL,
			config: MobilePlayerConfig(fileURL: NSBundle.mainBundle().URLForResource("PlayerSkin", withExtension: "json")!))
		
		player.title = media.title
		player.activityItems = [videoURL]
		player.view.frame = CGRect(x: 30, y: 25, width: 360, height: 200)
		//player.view.frame = CGRect(x: 30, y: 25, width: container.frame.width, height: container.frame.height)

		container.addSubview(player.view)
	}
	
	public func destroy() {
		
	}
}

public enum SambaPlayerError : ErrorType {
	case NoUrlFound
}
