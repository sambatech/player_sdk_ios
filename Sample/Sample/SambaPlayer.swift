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
	
	public var delegate: SambaPlayerDelegate?
	
	public var currentTime: Int {
		return Int(_player?.currentMediaTime() ?? 0)
	}
	
	private var _player: GMFPlayerViewController?
	private var _progressTimer: NSTimer = NSTimer()
	private var _hasStarted: Bool = false
	private var _stopping: Bool = false
	
	// MARK: Properties
	
	public var media: SambaMedia = SambaMedia() {
		didSet {
			destroy()
			// TODO: createThumb()
		}
	}
	
	public var isPlaying: Bool {
		return _player?.player.state.rawValue == 3
	}
	
	// MARK: Public Methods
	
	public func play() {
		if _player == nil {
			try! create()
			return
		}
		
		_player?.play()
	}
	
	public func pause() {
		_player?.pause()
	}
	
	public func stop() {
		_stopping = true
		pause()
		seek(0)
	}
    
    public func seek(pos: Int) {
		_player?.player.seekToTime(NSTimeInterval.init(pos))
    }
	
	public func destroy() {
		guard let player = _player else { return }
		
		stopTimer()
		player.player.reset()
		player.view.removeFromSuperview()
		player.removeFromParentViewController()
		
		_player = nil
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
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "playbackStateHandler:", name: kGMFPlayerPlaybackStateDidChangeNotification, object: gmf)
		
		gmf.play()
		
		_player = gmf
	}
	
	@objc private func playbackStateHandler(notification: NSNotification) {
		switch Int((_player?.player.state.rawValue)!) {
		case 2:
			delegate?.onLoad()
		case 3:
			if !_hasStarted {
				_hasStarted = true
				delegate?.onStart()
			}
			
			delegate?.onResume()
			startTimer()
		case 4:
			stopTimer()
			
			if !_stopping {
				delegate?.onPause()
			}
			else { _stopping = false }
		case 7:
			stopTimer()
			delegate?.onFinish()
		default: break
		}
	}
	
	@objc private func progressEvent() {
		delegate?.onProgress()
	}
	
	private func startTimer() {
		stopTimer()
		_progressTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("progressEvent"), userInfo: nil, repeats: true)
	}
	
	private func stopTimer() {
		_progressTimer.invalidate()
	}
}

public enum SambaPlayerError : ErrorType {
	case NoMediaUrlFound
}

public protocol SambaPlayerDelegate {
	func onLoad()
	func onStart()
	func onResume()
	func onPause()
	func onProgress()
	func onFinish()
}
