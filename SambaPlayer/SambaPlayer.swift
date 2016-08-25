//
//  SambaPlayer.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import UIKit

public class SambaPlayer : UIViewController {
	
	private var _player: GMFPlayerViewController?
	private var _parentView: UIView?
	private var _delegates = [SambaPlayerDelegate]()
	private var _progressTimer = NSTimer()
	private var _hasStarted = false
	private var _stopping = false
	private var _fullscreenAnimating = false
	private var _isFullscreen = false
	private var _hasMultipleOutputs = false
	private var _duration: Float = 0
	private var _currentOutput = -1
	private var _currentMenu: UIViewController?
	private var _wasPlayingBeforePause = false
	private var _state = kGMFPlayerStateEmpty
	
	// MARK: Properties
	
	///Stores the delegated methods for the player events
	public var delegate: SambaPlayerDelegate = FakeListener() {
		didSet {
			_delegates.append(delegate)
		}
	}
	
	///Current media time
	public var currentTime: Float {
		return Float(_player?.currentMediaTime() ?? 0)
	}
	
	///Current media duration
	public var duration: Float {
		if _duration == 0,
			let d = _player?.totalMediaTime() where d > 0 {
			_duration = Float(d)
		}
		
		return _duration
	}
	
	///Current media
	public var media: SambaMedia = SambaMedia() {
		didSet {
			destroy()
			
			if let index = media.outputs?.indexOf({ $0.isDefault }) {
				_currentOutput = index
			}
		}
	}
	
	///Flag if the media is or not playing
	public var isPlaying: Bool {
		return _state == kGMFPlayerStatePlaying || _state == kGMFPlayerStateBuffering
	}
	
	///Flag whether controls should be visible or not
	public var controlsVisible: Bool = true {
		didSet {
			(_player?.playerOverlayView() as! GMFPlayerOverlayView).visible = controlsVisible
		}
	}
	
	// MARK: Public Methods
	/**
	Default initializer
	**/
	public init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	/**
	Convenience initializer
	- parameter parentViewController:UIViewController The view-controller in which the player view-controller and view should to be embedded
	**/
	public convenience init(parentViewController: UIViewController) {
		self.init(parentViewController: parentViewController, andParentView: parentViewController.view)
	}
	
	/**
	Convenience initializer
	
	- Parameters:
		- parentViewController:UIViewController The view-controller in which the player view-controller should to be embedded
		- parentView:UIView The view in which the player view should to be embedded
	**/
	public convenience init(parentViewController: UIViewController, andParentView parentView: UIView) {
		self.init()
		
		dispatch_async(dispatch_get_main_queue()) {
			parentViewController.addChildViewController(self)
			self.didMoveToParentViewController(parentViewController)
			self.view.frame = parentView.bounds
			parentView.addSubview(self.view)
			parentView.setNeedsDisplay()
		}
		
		self._parentView = parentView
	}
	
	/**
	Required initializer
	
	- parameter aDecoder:NSCoder
	**/
	public required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	/**
	Play the media<br><br>
		
		player.play()
	*/
	public func play() {
		if _player == nil {
			dispatch_async(dispatch_get_main_queue()) { self.create() }
			return
		}
		
		_player?.play()
	}
	
	/**
	Pause the media<br><br>
	
		player.pause()
	*/
	public func pause() {
		_wasPlayingBeforePause = isPlaying
		_player?.pause()
	}
	
	/**
	Stop the media returning it to it´s initial time<br><br>
	
		player.stop()
	*/
	public func stop() {
		// avoid dispatching events
		_stopping = true
		
		pause()
		seek(0)
	}
	
	/**
	Seek the media to a given time<br><br>
			
		player.seek(20)
	
	- parameter: pos: Int Time in seconds
	*/
    public func seek(pos: Int) {
		_player?.player.seekToTime(NSTimeInterval(pos))
    }
	
	/**
	Change the current output<br><br>
	
		player.switchOutput(1)
	
	- parameter: value: Int Index of the output
	*/
	public func switchOutput(value: Int) {
		guard value != _currentOutput,
			let outputs = media.outputs
			where value < outputs.count else { return }
		
		_currentOutput = value
		_player?.player.switchUrl(outputs[value].url)
	}
	
	/**
	Destroy the player instance<br><br>
	
		player.destroy()
	
	*/
	public func destroy() {
		guard let player = _player else { return }
		
		for delegate in _delegates { delegate.onDestroy() }
		
		stopTimer()
		player.player.reset()
		detachVC(player)
		NSNotificationCenter.defaultCenter().removeObserver(self)
		
		_player = nil
	}
	
	/**
	Change the orientation of the player<br><br>
	
	- Parameters:
		- size:CGSize
		- withTransitionCoordinator coordinator
	*/
	public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
		
		guard !_fullscreenAnimating,
			let player = _player else { return }
		
		guard !media.isAudio else {
			var f = player.view.frame
			f.size.width = size.width
			player.view.frame = f
			player.view.setNeedsDisplay()
			return
		}
		
		let menu = _currentMenu
		
		if let menu = menu {
			hideMenu(menu, true)
		}
		
		let callback = {
			self._fullscreenAnimating = false
			
			if let menu = menu {
				self.showMenu(menu, true)
			}
		}
		
		if player.parentViewController == self {
			if UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) {
				_fullscreenAnimating = true
				_isFullscreen = true
				
				player.getControlsView().setMinimizeButtonImage(GMFResources.playerBarMaximizeButtonImage())
				detachVC(player)
				
				dispatch_async(dispatch_get_main_queue()) {
					self.presentViewController(player, animated: true, completion: callback)
				}
			}
		}
		else if UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) {
			_fullscreenAnimating = true
			
			detachVC(player) {
				self._isFullscreen = false
				
				player.getControlsView().setMinimizeButtonImage(GMFResources.playerBarMinimizeButtonImage())
				self.attachVC(player)
				callback()
			}
		}
	}
	
	/**
	Get all the supported orientation<br><br>
	- Returns: .AllButUpsideDown
	*/
	public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return .AllButUpsideDown
	}
	
	/**
	Fired up when the view disapears<br><br>
	Destroy the player after it
	
	*/
	public override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		
		guard !_fullscreenAnimating else { return }
		
		destroy()
	}
	
	// MARK: Internal Methods (may we publish them?)
	
	func showMenu(menu: UIViewController, _ mainActionOnly: Bool = false) {
		guard _hasStarted else { return }
		
		_currentMenu = menu
		
		if !mainActionOnly {
			pause()
		}
		
		if _isFullscreen {
			attachVC(menu, _player)
		}
		else {
			dispatch_async(dispatch_get_main_queue()) {
				self.presentViewController(menu, animated: false, completion: nil)
			}
		}
	}
	
	func hideMenu(menu: UIViewController, _ mainActionOnly: Bool = false) {
		detachVC(menu, _player, false)
		
		_currentMenu = nil
		
		if !mainActionOnly && _wasPlayingBeforePause {
			play()
		}
	}
	
	// MARK: Private Methods
	
	private func create() {
		var urlWrapped = media.url
		
		if let outputs = media.outputs where outputs.count > 0 {
			urlWrapped = outputs[0].url
			
			for output in outputs where output.isDefault {
				urlWrapped = output.url
			}
			
			_hasMultipleOutputs = outputs.count > 1
		}
		
		guard let url = urlWrapped else {
			print("\(self.dynamicType) error: No media URL found!")
			return
		}
		
		let gmf = GMFPlayerViewController(controlsPadding: CGRectMake(0, 0, 0, media.isAudio ? 10 : 0)) {
			guard let player = self._player else { return }
			
			if self._hasMultipleOutputs {
				player.getControlsView().showHdButton()
			}
			
			if self.media.isAudio {
				player.hideBackground()
				player.getControlsView().hideFullscreenButton()
				player.getControlsView().showPlayButton()
				(player.playerOverlayView() as! GMFPlayerOverlayView).controlsOnly = true
				player.playerOverlay().autoHideEnabled = false
				player.playerOverlay().controlsHideEnabled = false
				
				if !self.media.isLive {
					(player.playerOverlayView() as! GMFPlayerOverlayView).hideBackground()
					(player.playerOverlayView() as! GMFPlayerOverlayView).disableTopBar()
				}
			}
			
			if self.media.isLive {
				player.getControlsView().hideScrubber()
				player.getControlsView().hideTotalTime()
				player.addActionButtonWithImage(GMFResources.playerTitleLiveIcon(), name:"Live", target:player, selector:nil)
				(player.playerOverlayView() as! GMFPlayerOverlayView).hideBackground()
				(player.playerOverlayView() as! GMFPlayerOverlayView).topBarHideEnabled = false
			}
			
			if !self.controlsVisible {
				self.controlsVisible = false
			}
		}
		
		_player = gmf
		
		gmf.videoTitle = media.title
		gmf.controlTintColor = UIColor(media.theme)
		
		if media.isAudio {
			gmf.backgroundColor = UIColor(0x434343)
		}
		
		attachVC(gmf)
		
		let nc = NSNotificationCenter.defaultCenter()
			
		nc.addObserver(self, selector: #selector(playbackStateHandler),
		               name: kGMFPlayerPlaybackStateDidChangeNotification, object: gmf)
		
		nc.addObserver(self, selector: #selector(fullscreenTouchHandler),
		               name: kGMFPlayerDidMinimizeNotification, object: gmf)
		
		nc.addObserver(self, selector: #selector(hdTouchHandler),
		               name: kGMFPlayerDidPressHdNotification, object: gmf)
		
		// Tracking
		
		if !media.isLive && !media.isAudio {
			let _ = Tracking(self)
		}
		
		let nsUrl = NSURL(string: url)
		
		// IMA
		if !media.isAudio, let adUrl = media.adUrl {
			let mediaId = (media as? SambaMediaConfig)?.id ?? ""
			gmf.loadStreamWithURL(nsUrl, imaTag: "\(adUrl)&vid=[\(mediaId.isEmpty ? "live" : mediaId)]")
		}
			// default
		else {
			gmf.loadStreamWithURL(nsUrl)
			gmf.play()
		}
	}
	
	@objc private func playbackStateHandler() {
		guard let player = _player else { return }
		
		let lastState = _state
		
		_state = player.player.state
		
		#if DEBUG
		print("state: \(lastState) => \(_state)")
		#endif
		
		switch _state {
		case kGMFPlayerStateReadyToPlay:
			for delegate in _delegates { delegate.onLoad() }
			
		case kGMFPlayerStatePlaying:
			if !_hasStarted {
				_hasStarted = true
				for delegate in _delegates { delegate.onStart() }
			}
			
			if !player.isUserScrubbing && lastState != kGMFPlayerStateSeeking {
				for delegate in _delegates { delegate.onResume() }
			}
			
			startTimer()
			
		case kGMFPlayerStatePaused:
			stopTimer()
			
			if !_stopping && !player.isUserScrubbing && lastState != kGMFPlayerStateSeeking {
				for delegate in _delegates { delegate.onPause() }
			}
			else { _stopping = false }
			
		case kGMFPlayerStateFinished:
			stopTimer()
			for delegate in _delegates { delegate.onFinish() }
			
		default: break
		}
	}
	
	@objc private func progressEvent() {
		for delegate in _delegates { delegate.onProgress() }
	}
	
	@objc private func fullscreenTouchHandler() {
		UIDevice.currentDevice().setValue(_isFullscreen ? UIInterfaceOrientation.Portrait.rawValue :
			UIInterfaceOrientation.LandscapeLeft.rawValue, forKey: "orientation")
	}
	
	@objc private func hdTouchHandler() {
		showMenu(OutputMenuViewController(self, _currentOutput))
	}
	
	private func attachVC(vc: UIViewController, _ vcParent: UIViewController? = nil) {
		let p: UIViewController = vcParent ?? self
		
		dispatch_async(dispatch_get_main_queue()) {
			p.addChildViewController(vc)
			vc.didMoveToParentViewController(p)
			vc.view.frame = p.view.frame
			p.view.addSubview(vc.view)
			p.view.setNeedsDisplay()
		}
	}
	
	private func detachVC(vc: UIViewController, _ vcParent: UIViewController? = nil, _ animated: Bool = true, callback: (() -> Void)? = nil) {
		dispatch_async(dispatch_get_main_queue()) {
			if vc.parentViewController != (vcParent ?? self) {
				vc.dismissViewControllerAnimated(animated, completion: callback)
			}
			else {
				vc.view.removeFromSuperview()
				vc.removeFromParentViewController()
				callback?()
			}
		}
	}
	
	private func startTimer() {
		stopTimer()
		_progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: #selector(progressEvent), userInfo: nil, repeats: true)
	}
	
	private func stopTimer() {
		_progressTimer.invalidate()
	}
	
	class FakeListener : NSObject, SambaPlayerDelegate {
		func onLoad() {}
		func onStart() {}
		func onResume() {}
		func onPause() {}
		func onProgress() {}
		func onFinish() {}
		func onDestroy() {}
	}
}

/**
SambaPlayerDelegate protocol
*/
@objc public protocol SambaPlayerDelegate {
	///Fired up when player is loaded
	func onLoad()
	
	///Fired up when player is started
	func onStart()
	
	///Fired up when player is resumed ( from paused to play )
	func onResume()
	
	///Fired up when player is paused
	func onPause()
	
	///Fired up when player is playing ( fired each second of playing )
	func onProgress()
	
	///Fired up when player is finished
	func onFinish()
	
	///Fired up when player is destroyed
	func onDestroy()
}
