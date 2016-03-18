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
import MediaPlayer
import SwiftEventBus

public class SambaPlayer: UIView {
	
	public var player: MobilePlayerViewController?
    var progressTimer: NSTimer?
    public var currentTime: Int?
	
	public var media: SambaMedia = SambaMedia() {
		didSet {
			destroy()
			// TODO: createThumb()
		}
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
		player?.stop()
	}
    
    public func seek(pos: Int) {

    }
	
	public func addEventListener(type: String, listener: (NSNotification!) -> () ) {
		SwiftEventBus.onMainThread(self, name: type, handler: listener)
	}
	
	public func removeEventListener(type: String) {
		SwiftEventBus.unregister(self, name: type)
	}
	
	public func destroy() {
		
	}
	
	// MARK: Private Methods
	
	private func create() throws {
		var urlWrapped = media.url
		
		if let outputs = media.outputs where outputs.count > 0 {
			urlWrapped = outputs[0].url
		}
		
		guard let url = urlWrapped else {
			throw SambaPlayerError.NoMediaUrlFound
		}

		let videoURL = NSURL(string: url)!
		let config = MobilePlayerConfig(fileURL: NSBundle.mainBundle().URLForResource("PlayerSkin", withExtension: "json")!)
		
		/*if let sliderIndex = config.bottomBarConfig.elements.indexOf({$0 is SliderConfig}) {
			(config.bottomBarConfig.elements[sliderIndex] as SliderConfig).maximumTrackTintColor = media.theme
		}*/
		
		let player = MobilePlayerViewController(contentURL: videoURL, config: config)
        
		player.title = media.title
		player.activityItems = [videoURL]
		
		player.view.frame = bounds
		
		self.addSubview(player.view)
		
		self.player = player
        
        subcribeEvents()
	}
    
    // MARK: Events
    private func subcribeEvents() {
        guard let player = self.player else {
            return
        }
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        var eventType:String = ""
		
        notificationCenter.addObserverForName(
            MPMoviePlayerPlaybackStateDidChangeNotification,
            object: player.moviePlayer,
			queue: NSOperationQueue.mainQueue()) { notification in
                switch player.state {
                case .Playing:
                    eventType = "play"
                    player.moviePlayer.setFullscreen(true, animated: false)
                case .Paused:
                    eventType = "pause"
                case .Buffering:
                    eventType = "buffer"
                default:
                    break
                }

                SwiftEventBus.postToMainThread(eventType, sender: self)
        }
        
        notificationCenter.addObserverForName(
            MPMoviePlayerLoadStateDidChangeNotification,
            object: player.moviePlayer,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { notification in
				if player.state != .Idle { return }
				
                SwiftEventBus.postToMainThread("load", sender: self)
            }
        )
        
        notificationCenter.addObserverForName(
            MPMoviePlayerPlaybackDidFinishNotification,
            object: player.moviePlayer,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { notification in
                SwiftEventBus.postToMainThread("finish", sender: self)
            }
        )
        
        notificationCenter.addObserverForName(
            MPMoviePlayerTimedMetadataUpdatedNotification,
            object: player.moviePlayer,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { notification in

				print(notification)
                SwiftEventBus.postToMainThread("progress", sender: self)
            }
        )

        progressTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("progressEvent"), userInfo: nil, repeats: true)
        
    }
    
    public func progressEvent() {
        guard let player = self.player else {
            return
        }
        
        if player.state == .Playing {
            self.currentTime = Int(ceil(player.moviePlayer.currentPlaybackTime))
            SwiftEventBus.postToMainThread("progress", sender: self)
        }
    }


}

public enum SambaPlayerError : ErrorType {
	case NoMediaUrlFound
}
