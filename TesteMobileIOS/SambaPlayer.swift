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

public class SambaPlayer: UIView {
	
	public var player: MobilePlayerViewController?
	
	public var media: SambaMedia = SambaMedia() {
		didSet {
			destroy()
			//createThumb()
		}
	}
	
	// MARK: Public Methods
	
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
		
		let notificationCenter = NSNotificationCenter.defaultCenter()
		
		notificationCenter.addObserverForName(
			MPMoviePlayerPlaybackStateDidChangeNotification,
			object: player.moviePlayer,
			queue: NSOperationQueue.mainQueue()
		) { notification in
			print("Playback: \(player.previousState) >> \(player.state)")
		}
		
		notificationCenter.addObserverForName(
			MPMoviePlayerLoadStateDidChangeNotification,
			object: player.moviePlayer,
			queue: NSOperationQueue.mainQueue(),
			usingBlock: { notification in
				print("Load: \(player.previousState) >> \(player.state)")
			}
		)
		
		notificationCenter.addObserverForName(
			MPMoviePlayerPlaybackDidFinishNotification,
			object: player.moviePlayer,
			queue: NSOperationQueue.mainQueue(),
			usingBlock: { notification in
				print("Finish: \(player.previousState) >> \(player.state)")
			}
		)
		
		notificationCenter.addObserverForName(
			MPMoviePlayerTimedMetadataUpdatedNotification,
			object: player.moviePlayer,
			queue: NSOperationQueue.mainQueue(),
			usingBlock: { notification in
				print("Progress: >> \(player.state)")
			}
		)
		
		self.addSubview(player.view)
		
		self.player = player
	}
	
	public func destroy() {
		
	}
}

public enum SambaPlayerError : ErrorType {
	case NoUrlFound
}
