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
	
	public func addEventListener(type: String, listener: (NSNotification!) -> () ) {
		SwiftEventBus.onBackgroundThread(self, name: type, handler: listener)
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
		
		let player = MobilePlayerViewController(contentURL: videoURL,
			config: MobilePlayerConfig(fileURL: NSBundle.mainBundle().URLForResource("PlayerSkin", withExtension: "json")!))
		
		player.title = media.title
		player.activityItems = [videoURL]
		
		subcribeEvents()
		
		player.view.frame = bounds
		
		self.addSubview(player.view)
		
		self.player = player
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
                case .Paused:
                    eventType = "pause"
                case .Buffering:
                    eventType = "buffer"
                default:
                    break
                }

                print("Playback: \(player.previousState) >> \(player.state)")
                SwiftEventBus.post(eventType, sender: self)
        }
        
        notificationCenter.addObserverForName(
            MPMoviePlayerLoadStateDidChangeNotification,
            object: player.moviePlayer,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { notification in
				if player.state != .Idle { return }
				
                SwiftEventBus.post("load", sender: self)
            }
        )
        
        notificationCenter.addObserverForName(
            MPMoviePlayerPlaybackDidFinishNotification,
            object: player.moviePlayer,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { notification in
                SwiftEventBus.post("finish", sender: self)
            }
        )
        
        notificationCenter.addObserverForName(
            MPMoviePlayerTimedMetadataUpdatedNotification,
            object: player.moviePlayer,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { notification in
				print(notification)
                SwiftEventBus.post("progress", sender: self)
            }
        )
    }
}

public enum SambaPlayerError : ErrorType {
	case NoMediaUrlFound
}
