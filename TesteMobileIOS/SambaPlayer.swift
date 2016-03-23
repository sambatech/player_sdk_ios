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

public class SambaPlayer: UIViewController {
	
    public private(set) var currentTime: Int = 0
	
	private var player: MobilePlayerViewController?
	private var progressTimer: NSTimer?
	
	// MARK: Properties
	
	public var media: SambaMedia = SambaMedia() {
		didSet {
			destroy()
			// TODO: createThumb()
		}
	}
	
	public var isPlaying: Bool {
		return player?.state == .Playing
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
		var hasMultipleOutputs = false
		
		if let outputs = media.outputs where outputs.count > 0 {
			urlWrapped = outputs[0].url
			hasMultipleOutputs = outputs.count > 1
		}
		
		guard let url = urlWrapped else {
			throw SambaPlayerError.NoMediaUrlFound
		}

		let videoURL = NSURL(string: url)!
		
		guard let jsonString = (try? String(contentsOfURL: NSBundle.mainBundle().URLForResource("PlayerSkin", withExtension: "json")!, encoding: NSUTF8StringEncoding)),
			jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding),
			var skin = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: [])) as? [String: AnyObject] else {
			
			print("\(self.dynamicType) Error: Failed to parse skin JSON!")
			return
		}
		
		//let config = MobilePlayerConfig(fileURL: NSBundle.mainBundle().URLForResource("PlayerSkin", withExtension: "json")!)
		
		/*if let sliderIndex = config.bottomBarConfig.elements.indexOf({$0 is SliderConfig}) {
			(config.bottomBarConfig.elements[sliderIndex] as SliderConfig).minimumTrackTintColor = media.theme
		}*/
		
		if var bottomBarJson = skin["bottomBar"] as? [String: AnyObject],
			elementsJson = bottomBarJson["elements"] as? [AnyObject] {

			// TODO: check hasMultipleOutputs show/hide HD button
			for (i, element) in elementsJson.enumerate() where element["identifier"] as? String == "playback" {
				if var playbackElement = element as? [String: AnyObject] {
					playbackElement["minimumTrackTintColor"] = media.theme
					elementsJson[i] = playbackElement
				}
			}
			
			bottomBarJson["elements"] = elementsJson
			skin["bottomBar"] = bottomBarJson
		}

		let player = MobilePlayerViewController(
			contentURL: videoURL,
			config: MobilePlayerConfig(dictionary: skin),
			prerollViewController: nil,
			pauseOverlayViewController: PlayOverlayViewController(self))

		player.title = media.title
		player.activityItems = [videoURL]
		
		player.view.frame = view.bounds
		
		view.addSubview(player.view)
		
		self.player = player
		
        subcribeEvents()
	}
    
    // MARK: Events
	
    private func subcribeEvents() {
        guard let player = self.player else {
            return
        }
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
		let queue = NSOperationQueue.mainQueue()
		let playerCore = player.moviePlayer
		var eventType:String = ""
		
        notificationCenter.addObserverForName(
            MPMoviePlayerPlaybackStateDidChangeNotification,
            object: playerCore,
			queue: queue) { notification in
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

                SwiftEventBus.postToMainThread(eventType, sender: self)
        }
        
        notificationCenter.addObserverForName(
            MPMoviePlayerLoadStateDidChangeNotification,
            object: playerCore,
            queue: queue,
            usingBlock: { notification in
				if player.state != .Idle { return }
                SwiftEventBus.postToMainThread("load", sender: self)
            }
        )
        
        notificationCenter.addObserverForName(
            MPMoviePlayerPlaybackDidFinishNotification,
            object: playerCore,
            queue: queue,
            usingBlock: { notification in
                SwiftEventBus.postToMainThread("finish", sender: self)
            }
        )
        
        notificationCenter.addObserverForName(
            MPMoviePlayerTimedMetadataUpdatedNotification,
            object: playerCore,
            queue: queue,
            usingBlock: { notification in
                SwiftEventBus.postToMainThread("progress", sender: self)
            }
        )

		(player.getViewForElementWithIdentifier("fullscreenButton") as? UIButton)?.addCallback({
			print("fullscreen!")
		}, forControlEvents: .TouchUpInside)
		
        progressTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("progressEvent"), userInfo: nil, repeats: true)

		// creates output menu when multiple outputs
		if let outputs = media.outputs where outputs.count > 1,
			let parent = self.parentViewController {
				
			let outputMenu = OutputMenuViewController(outputs)
			
			(player.getViewForElementWithIdentifier("hdButton") as? UIButton)?.addCallback({
				self.pause()
				parent.addChildViewController(outputMenu)
				parent.view.addSubview(outputMenu.view)
				outputMenu.didMoveToParentViewController(parent)
			}, forControlEvents: .TouchUpInside)
		}
    }
    
    func progressEvent() {
        guard let player = self.player else { return }
        
        if player.state == .Playing {
            self.currentTime = Int(ceil(player.moviePlayer.currentPlaybackTime))
            SwiftEventBus.postToMainThread("progress", sender: self)
        }
    }
}

public enum SambaPlayerError : ErrorType {
	case NoMediaUrlFound
}

/*/// Indicates if player controls are hidden. Setting its value will animate controls in or out.
public var controlsHidden: Bool {
	get {
		return controlsView.controlsHidden
	}
	set {
		if newValue && state == .Paused { return }
		
		newValue ? hideControlsTimer?.invalidate() : resetHideControlsTimer()
		controlsView.controlsHidden = newValue
	}
}*/
