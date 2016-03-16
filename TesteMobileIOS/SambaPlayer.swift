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
			//createThumb()
		}
	}
	
	// MARK: Public Methods
	
    
    // MARK: methods
	public func play() {
		if player == nil {
			try! create()
			return
		}
		
		player!.play()
	}
	
	public func pause() {
		if let _ = player {
			player!.pause()
		}
	}
	
	// MARK: Private Methods
	private func create() throws {
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
		
		self.addSubview(player.view)
		
		self.player = player
        
        //Subscribing events
        subcribe()
	}
    
    //MARK: Events
    private func subcribe() {
        guard let player = self.player else {
            return
        }
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        var eventType:String = ""
        
        notificationCenter.addObserverForName(
            MPMoviePlayerPlaybackStateDidChangeNotification,
            object: player.moviePlayer,
            queue: NSOperationQueue.mainQueue()
            ) { notification in
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
                print("progressssss")
                SwiftEventBus.post("progress", sender: self)
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
            SwiftEventBus.post("progress", sender: self)
        }
    }
    
    public func addEventListener(type: String, listener: (NSNotification!) -> () ) {
        SwiftEventBus.onBackgroundThread(self, name: type, handler: listener)
    }
    
    public func removeEventListener(type: String) {
        SwiftEventBus.unregister(self, name: type)
    }
 	
	public func destroy() {

	}
}

public enum SambaPlayerError : ErrorType {
	case NoUrlFound
}
