//
//  SambaPlayer.swift
//
//
//  Created by Leandro Zanol on 3/9/16.
//
//

import Foundation
import UIKit
import MediaPlayer

public class SambaPlayer: UIViewController {
	
    public private(set) var currentTime: Int = 0
	
	private var player: GMFPlayerViewController?
	private var progressTimer: NSTimer?
	
	// MARK: Properties
	
	public var media: SambaMedia = SambaMedia() {
		didSet {
			destroy()
			// TODO: createThumb()
		}
	}
	
	public var isPlaying: Bool {
		return false;
	}
	
	// MARK: Public Methods
	
	public func play() {
		if player == nil {
			try! create()
			return
		}
		
		player?.play()
	}
	
	public func pause() {
		player?.pause()
	}
	
	public func stop() {
	}
    
    public func seek(pos: Int) {

    }
	
	public func addEventListener(type: String, listener: (NSNotification!) -> () ) {
		//SwiftEventBus.onMainThread(self, name: type, handler: listener)
	}
	
	public func removeEventListener(type: String) {
		//SwiftEventBus.unregister(self, name: type)
	}
	
	public func destroy() {
		
	}
	
	// MARK: Private Methods
	
	private func create() throws {
		var urlWrapped = media.url
		// TODO: check hasMultipleOutputs show/hide HD button
		var hasMultipleOutputs = false
		
		if let outputs = media.outputs where outputs.count > 0 {
			urlWrapped = outputs[0].url
			hasMultipleOutputs = outputs.count > 1
		}
		
		guard let url = urlWrapped else {
			throw SambaPlayerError.NoMediaUrlFound
		}

		let gmf = GMFPlayerViewController()
		
		//http://gbbrpvbps-sambavideos.akamaized.net/account/37/2/2015-11-05/video/cb7a5d7441741d8bcb29abc6521d9a85/marina_360p.mp4
		gmf.loadStreamWithURL(NSURL(string: url))
		gmf.videoTitle = media.title
		
		addChildViewController(gmf)
		gmf.didMoveToParentViewController(self)
		gmf.view.frame = view.frame
		view.addSubview(gmf.view)
		view.setNeedsDisplay()
		
		//NSNotificationCenter.defaultCenter().addObserver(self, selector: "asdf:", name: kGMFPlayerPlaybackStateDidChangeNotification, object: gmf)
		
		gmf.play()
		
		self.player = gmf
	}
	
//	@objc private func asdf(NSNotification notification) {
//		print(notification);
//	}
}

public enum SambaPlayerError : ErrorType {
	case NoMediaUrlFound
}
