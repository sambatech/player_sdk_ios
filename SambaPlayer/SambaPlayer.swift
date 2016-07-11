//
//  SambaPlayer.swift
//
//
//  Created by Leandro Zanol on 3/9/16.
//
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
	private var _lastOutput = -1
	
	// MARK: Properties
	
	public var delegate: SambaPlayerDelegate? {
		// TODO: remove this (add eventbus alike control)
		didSet {
			guard let value = delegate else { return }
			_delegates.append(value)
		}
	}
	
	public var currentTime: Float {
		return Float(_player?.currentMediaTime() ?? 0)
	}
	
	public var duration: Float {
		return Float(_player?.totalMediaTime() ?? 0)
	}
	
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
	
	public func switchOutput(value: Int) {
		guard let outputs = media.outputs
			where value != _lastOutput && value < outputs.count else { return }
		
		_lastOutput = value
		_player?.player.switchUrl(outputs[value].url)
	}
	
	public func destroy() {
		guard let player = _player else { return }
		
		for delegate in _delegates { delegate.onDestroy() }
		
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
				
				player.getControlsView().setMinimizeButtonImage(GMFResources.playerBarMaximizeButtonImage())
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
				
				player.getControlsView().setMinimizeButtonImage(GMFResources.playerBarMinimizeButtonImage())
				self.attachVC(player)
			}
		}
		
		super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
	}
	
	public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return .AllButUpsideDown
	}
	
	public override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		
		guard !_fullscreenAnimating else { return }
		
		destroy()
	}
	
	// MARK: Internal Methods
	
	func attachVC(vc: UIViewController, _ vcParent: UIViewController? = nil) {
		let p: UIViewController = vcParent ?? self
		
		p.addChildViewController(vc)
		vc.didMoveToParentViewController(p)
		vc.view.frame = p.view.frame
		p.view.addSubview(vc.view)
		p.view.setNeedsDisplay()
	}
	
	func detachVC(vc: UIViewController, callback: (() -> Void)? = nil) {
		if vc.parentViewController != self {
			vc.dismissViewControllerAnimated(true, completion: callback)
		}
		else {
			vc.view.removeFromSuperview()
			vc.removeFromParentViewController()
			callback?()
		}
	}
	
	// MARK: Private Methods
	
	private func create() throws {
		var urlWrapped = media.url
		
		if let outputs = media.outputs where outputs.count > 0 {
			urlWrapped = outputs[0].url
			
			for output in outputs where output.isDefault {
				urlWrapped = output.url
			}
			
			_hasMultipleOutputs = outputs.count > 1
		}
		
		guard let url = urlWrapped else {
			throw SambaPlayerError.NoMediaUrlFound
		}

		let gmf = GMFPlayerViewController(initedBlock: {
			if self._hasMultipleOutputs {
				self._player?.getControlsView().showHdButton()
			}
			
			if self.media.isAudio {
				self._player?.hideBackground()
				self._player?.getControlsView().hideFullscreenButton()
				self._player?.getControlsView().showPlayButton()
				self._player?.playerOverlay().autoHideEnabled = false
				self._player?.playerOverlay().controlsHideEnabled = false
			}
		})
		
		_player = gmf
		
		gmf.videoTitle = media.title
		gmf.controlTintColor = UIColor(media.theme)
		
		if media.isAudio {
			gmf.backgroundColor = UIColor(0x434343)
		}
		
		gmf.loadStreamWithURL(NSURL(string: url))
		
		attachVC(gmf)
		
		let nc = NSNotificationCenter.defaultCenter()
			
		nc.addObserver(self, selector: #selector(playbackStateHandler),
		               name: kGMFPlayerPlaybackStateDidChangeNotification, object: gmf)
		
		nc.addObserver(self, selector: #selector(fullscreenTouchHandler),
		               name: kGMFPlayerDidMinimizeNotification, object: gmf)
		
		nc.addObserver(self, selector: #selector(hdTouchHandler),
		               name: kGMFPlayerDidPressHdNotification, object: gmf)
		
		// IMA
		
		if !media.isAudio,
			let adUrl = media.adUrl,
			ima = GMFIMASDKAdService(GMFVideoPlayer: gmf) {
			gmf.registerAdService(ima)
			ima.requestAdsWithRequest(adUrl)
		}
		
		let _ = Tracking(self)
		
		gmf.play()
	}
	
	@objc private func playbackStateHandler() {
		switch Int((_player?.player.state.rawValue)!) {
		case 2:
			for delegate in _delegates { delegate.onLoad() }
		case 3:
			if !_hasStarted {
				_hasStarted = true
				for delegate in _delegates { delegate.onStart() }
			}
			
			for delegate in _delegates { delegate.onResume() }
			startTimer()
		case 4:
			stopTimer()
			
			if !_stopping {
				for delegate in _delegates { delegate.onPause() }
			}
			else { _stopping = false }
		case 7:
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
		print("HD button tapped")
		//pause()
		//showHdMenu()
	}

	private func startTimer() {
		stopTimer()
		_progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: #selector(progressEvent), userInfo: nil, repeats: true)
	}
	
	private func stopTimer() {
		_progressTimer.invalidate()
	}
	
	private func showHdMenu() {
		if _isFullscreen {
			attachVC(OutputMenuViewController(self))
		}
		else {
			presentViewController(OutputMenuViewController(self), animated: false, completion: nil)
		}
	}
}

public enum SambaPlayerError : ErrorType {
	case NoMediaUrlFound
}

// TODO: research how to have optional impls
public protocol SambaPlayerDelegate {
	func onLoad()
	func onStart()
	func onResume()
	func onPause()
	func onProgress()
	func onFinish()
	func onDestroy()
}
