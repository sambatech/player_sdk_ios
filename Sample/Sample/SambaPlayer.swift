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
	private var _fullscreenAnimating: Bool = false
	private var _parentView: UIView?
	private var _isFullscreen: Bool = false
	
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
	
	public init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	public convenience init(_ parentViewController: UIViewController) {
		self.init(parentViewController, parentView: parentViewController.view)
	}
	
	public convenience init(_ parentViewController: UIViewController, parentView: UIView) {
		self.init()
		
		parentViewController.addChildViewController(self)
		didMoveToParentViewController(parentViewController)
		view.frame = parentView.bounds
		parentView.addSubview(view)
		parentView.setNeedsDisplay()
		
		self._parentView = parentView
	}
	
	public required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

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
		// avoid dispatching events
		_stopping = true
		
		pause()
		seek(0)
	}
    
    public func seek(pos: Int) {
		_player?.player.seekToTime(NSTimeInterval(pos))
    }
	
	public func destroy() {
		guard let player = _player else { return }
		
		stopTimer()
		player.player.reset()
		detachVC(player)
		NSNotificationCenter.defaultCenter().removeObserver(self)
		
		_player = nil
	}
	
	public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		guard let player = _player where !_fullscreenAnimating else { return }
		
		if player.parentViewController == self {
			if UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) {
				_fullscreenAnimating = true
				_isFullscreen = true
				
				//player.videoPlayerOverlayViewController.player
				detachVC(player)
				
				presentViewController(player, animated: true) {
					self._fullscreenAnimating = false
				}
			}
		}
		else if UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) {
			_fullscreenAnimating = true
			
			detachVC(player) {
				self._fullscreenAnimating = false
				self._isFullscreen = false
				self.attachVC(player)
			}
		}
		
		super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
	}
	
	public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.AllButUpsideDown
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
		gmf.videoTitle = media.title
		gmf.controlTintColor = UIColor(media.theme)
		gmf.loadStreamWithURL(NSURL(string: url))
		
		attachVC(gmf)
		
		let nc = NSNotificationCenter.defaultCenter()
			
		nc.addObserver(self, selector: #selector(playbackStateHandler),
		               name: kGMFPlayerPlaybackStateDidChangeNotification, object: gmf)
		
		nc.addObserver(self, selector: #selector(fullscreenHandler),
		               name: kGMFPlayerDidMinimizeNotification, object: gmf)
		
		// IMA
		
		if let adUrl = media.adUrl,
			ima = GMFIMASDKAdService(GMFVideoPlayer: gmf) {
			gmf.registerAdService(ima)
			ima.requestAdsWithRequest(adUrl)
		}
		
		gmf.play()
		
		_player = gmf
	}
	
	@objc private func fullscreenHandler() {
		if _isFullscreen {
			print("exiting fullscreen")
			UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
		}
		else {
			print("entering fullscreen")
			UIDevice.currentDevice().setValue(UIInterfaceOrientation.LandscapeLeft.rawValue, forKey: "orientation")
		}
	}
	
	@objc private func playbackStateHandler() {
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
		_progressTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(SambaPlayer.progressEvent), userInfo: nil, repeats: true)
	}
	
	private func stopTimer() {
		_progressTimer.invalidate()
	}
	
	private func attachVC(vc: UIViewController, _ vcParent: UIViewController? = nil) {
		let p: UIViewController = vcParent ?? self
		
		p.addChildViewController(vc)
		vc.didMoveToParentViewController(p)
		vc.view.frame = p.view.frame
		p.view.addSubview(vc.view)
		p.view.setNeedsDisplay()
	}
	
	private func detachVC(vc: UIViewController, callback: (() -> Void)? = nil) {
		if vc.parentViewController != self {
			vc.dismissViewControllerAnimated(true, completion: callback)
		}
		else {
			vc.view.removeFromSuperview()
			vc.removeFromParentViewController()
		}
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
