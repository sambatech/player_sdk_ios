//
//  SambaPlayer.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import UIKit

/// Responsible for managing media playback
public class SambaPlayer : UIViewController, ErrorScreenDelegate {
	
	private var _player: GMFPlayerViewController?
	private var _parentView: UIView?
	private var _currentMenu: UIViewController?
	private var _errorScreen: UIViewController?
	private var _captionsScreen: UIViewController?
	private var _delegates = [SambaPlayerDelegate]()
	private var _progressTimer = Timer()
	private var _hasStarted = false
	private var _stopping = false
	private var _fullscreenAnimating = false
	private var _isFullscreen = false
	private var _hasMultipleOutputs = false
	private var _pendingPlay = false
	private var _duration: Float = 0
	private var _currentOutput = -1
	private var _wasPlayingBeforePause = false
	private var _state = kGMFPlayerStateEmpty
	private var _thumb: UIButton?
	private var _decryptDelegate: AssetLoaderDelegate?
	private var _disabled = false
	private var _errorManager: ErrorManager?
	
	// MARK: Properties
	
	/// Stores the delegated methods for the player events
	public var delegate: SambaPlayerDelegate = FakeListener() {
		didSet {
			_delegates.append(delegate)
		}
	}
	
	/// Current media time
	public var currentTime: Float {
		return Float(_player?.currentMediaTime() ?? 0)
	}
	
	/// Current media duration
	public var duration: Float {
		if _duration == 0,
			let d = _player?.totalMediaTime(), d > 0 {
			_duration = Float(d)
		}
		
		return _duration
	}
	
	/// Current media
	public var media: SambaMedia = SambaMedia() {
		didSet {
			// check jailbreak
			if let m = media as? SambaMediaConfig,
				m.blockIfRooted && GMFHelpers.isDeviceJailbroken() {
				dispatchError(SambaPlayerError.rootedDevice)
				return
			}
			
			// reset player
			destroy()
			
			DispatchQueue.main.async {
				if self.media.isAudio {
					self.create(false)
				}
				else {
					self.createThumb()
				}
			}
		}
	}
	
	/// Whether media is playing or not
	public var isPlaying: Bool {
		return _state == kGMFPlayerStatePlaying || _state == kGMFPlayerStateBuffering
	}
	
	/// Whether controls should be visible or not
	public var controlsVisible: Bool = true {
		didSet {
			(_player?.playerOverlayView() as? GMFPlayerOverlayView)?.visible = controlsVisible
		}
	}
	
	// MARK: Public Methods
	/**
	Default initializer
	*/
	public init() {
		super.init(nibName: nil, bundle: nil)
		_errorManager = ErrorManager(self)
	}
	
	/**
	Convenience initializer
	
	- parameter parentViewController: The view-controller in which the player view-controller and view should be embedded
	*/
	public convenience init(parentViewController: UIViewController) {
		self.init(parentViewController: parentViewController, andParentView: parentViewController.view)
	}
	
	/**
	Convenience initializer
	
	- parameter parentViewController: The view-controller in which the player view-controller should be embedded
	- parameter parentView: The view in which the player view should be embedded
	*/
	public convenience init(parentViewController: UIViewController, andParentView parentView: UIView) {
		self.init()
		
		DispatchQueue.main.async {
			parentViewController.addChildViewController(self)
			self.didMove(toParentViewController: parentViewController)
			self.view.frame = parentView.bounds
			parentView.addSubview(self.view)
			parentView.setNeedsDisplay()
		}
		
		self._parentView = parentView
	}
	
	public required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	/**
	Plays the media
	*/
	public func play() {
		if _disabled { return }
		
		guard let player = _player else {
			DispatchQueue.main.async { self.create() }
			return
		}
		
		player.play()
	}
	
	/**
	Pauses the media
	*/
	public func pause() {
		_wasPlayingBeforePause = isPlaying
		_player?.pause()
	}
	
	/**
	Stops the media returning it to its initial time
	*/
	public func stop() {
		// avoid dispatching events
		_stopping = true
		
		pause()
		seek(0)
	}
	
	/**
	Moves the media to a given time
			
		player.seek(20)
	
	- parameter pos: Time in seconds
	*/
    public func seek(_ pos: Float) {
		// do not seek on live
		guard !media.isLive else { return }
		
		_player?.player.seek(toTime: TimeInterval(pos))
    }
	
	/**
	Changes the current output
	
		player.switchOutput(1)
	
	- parameter value: Index of the output
	*/
	public func switchOutput(_ value: Int) {
		guard value != _currentOutput,
			let outputs = media.outputs,
			value < outputs.count else { return }
		
		_currentOutput = value
		
		guard let url = URL(string: outputs[value].url) else {
			dispatchError(SambaPlayerError.invalidUrl.setValues("Invalid output URL"))
			return
		}
		
		let asset = AVURLAsset(url: url)
		
		if let m = media as? SambaMediaConfig,
			let drmRequest = m.drmRequest {
			// weak reference delegate, must retain a reference to it
			_decryptDelegate = AssetLoaderDelegate(asset: asset, assetName: m.id, drmRequest: drmRequest)
		}
		
		_player?.player.switch(asset)
	}
	
	/**
	Changes the current caption
	
		player.changeCaption(1)
	
	- parameter value: Index of the caption
	*/
	public func changeCaption(_ value: Int) {
		guard let screen = _captionsScreen as? CaptionsScreen else { return }
		screen.changeCaption(value)
	}
		
	/**
	Destroys the player instance
	
		player.destroy()
	
	- parameter error: (optional) Error type to show
	*/
	public func destroy(withError error: SambaPlayerError? = nil) {
		if let error = error {
			_disabled = true
			showError(error)
		}
		else {
			destroyScreen(&_errorScreen)
			destroyScreen(&_captionsScreen)
		}
		
		for delegate in _delegates { delegate.onDestroy?() }
		
		destroyInternal()
	}
	
	// MARK: Overrides
	
	public override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return .allButUpsideDown
	}
	
	public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		guard !_fullscreenAnimating,
			let player = _player else { return }
		
		guard !media.isAudio else {
			var f = player.view.frame
			f.size.width = size.width
			player.view.frame = f
			player.view.setNeedsDisplay()
			return
		}
		
		if let menu = _currentMenu {
			hideMenu(menu, true)
		}
		
		let callback = {
			self._fullscreenAnimating = false
			
			if let menu = self._currentMenu {
				self.showMenu(menu, true)
			}
		}
		
		if player.parent == self {
			if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
				_fullscreenAnimating = true
				_isFullscreen = true
				
				player.getControlsView().setMinimizeButtonImage(GMFResources.playerBarMaximizeButtonImage())
				detachVC(player)
				
				DispatchQueue.main.async {
					self.present(player, animated: true, completion: callback)
				}
			}
		}
		else if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
			_fullscreenAnimating = true
			
			detachVC(player) {
				self._isFullscreen = false
				
				player.getControlsView().setMinimizeButtonImage(GMFResources.playerBarMinimizeButtonImage())
				self.attachVC(player)
				callback()
			}
		}
	}
	
	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		guard !_fullscreenAnimating else { return }
		
		destroy()
	}
	
	// MARK: Internal Methods (may we publish them?)
	
	func showMenu(_ menu: UIViewController, _ mainActionOnly: Bool = false) {
		guard _hasStarted else { return }
		
		_currentMenu = menu
		
		if !mainActionOnly {
			pause()
		}
		
		if _isFullscreen {
			attachVC(menu, _player)
		}
		else {
			DispatchQueue.main.async {
				self.present(menu, animated: false, completion: nil)
			}
		}
	}
	
	func hideMenu(_ menu: UIViewController, _ mainActionOnly: Bool = false) {
		detachVC(menu, _player, false)
		
		if !mainActionOnly {
			if _wasPlayingBeforePause {
				play()
			}
			
			_currentMenu = nil
		}
	}
	
	// MARK: Private Methods
	
	private func create(_ autoPlay: Bool = true, _ force: Bool = false) {
		if !force, let player = _player {
			if autoPlay { player.play() }
			return
		}
		
		// re-enable player
		_pendingPlay = false
		_disabled = false
		
		guard let asset = createAsset(decideUrl()) else { return }
		
		if let m = media as? SambaMediaConfig,
			let drmRequest = m.drmRequest {
			// weak reference init, must retain a strong reference to it
			_decryptDelegate = AssetLoaderDelegate(asset: asset, assetName: m.id, drmRequest: drmRequest)
		}
		
		guard let gmf = (GMFPlayerViewController(controlsPadding: CGRect(x: 0, y: 0, width: 0, height: media.isAudio ? 10 : 0)) {
			guard let player = self._player else { return }
			
			if self._hasMultipleOutputs {
				player.getControlsView().showHdButton()
			}
			
			// captions
			if let captions = self.media.captions, captions.count > 0 {
				self.showScreen(CaptionsScreen(player: self, captions: captions, config: self.media.captionsConfig),
				                &self._captionsScreen, player.playerOverlay())
				player.getControlsView().showCaptionsButton()
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
				player.addActionButton(with: GMFResources.playerTitleLiveIcon(), name:"Live", target:player, selector:nil)
				(player.playerOverlayView() as! GMFPlayerOverlayView).hideBackground()
				(player.playerOverlayView() as! GMFPlayerOverlayView).topBarHideEnabled = false
			}
			
			if !self.controlsVisible {
				self.controlsVisible = false
			}
		}) else {
			dispatchError(SambaPlayerError.creatingPlayer)
			return
		}
	
		_player = gmf
		
		gmf.videoTitle = media.title
		gmf.controlTintColor = UIColor(media.theme)
		
		if media.isAudio {
			gmf.backgroundColor = UIColor(0x434343)
		}
		
		destroyThumb()
		attachVC(gmf)
		
		let nc = NotificationCenter.default
		
		nc.addObserver(self, selector: #selector(playbackStateHandler),
		               name: NSNotification.Name.gmfPlayerPlaybackStateDidChange, object: gmf)
		
		nc.addObserver(self, selector: #selector(fullscreenTouchHandler),
		               name: NSNotification.Name.gmfPlayerDidMinimize, object: gmf)
		
		nc.addObserver(self, selector: #selector(hdTouchHandler),
		               name: NSNotification.Name.gmfPlayerDidPressHd, object: gmf)
		
		nc.addObserver(self, selector: #selector(captionsTouchHandler),
		               name: NSNotification.Name.gmfPlayerDidPressCaptions, object: gmf)
		
		// Tracking
		if !media.isLive && !media.isAudio {
			let _ = Tracking(self)
		}
		
		loadAsset(asset, autoPlay)
	}
	
	private func createThumb() {
		guard let thumbImage = media.thumb else {
			#if DEBUG
			print("\(type(of: self)): no thumb found.")
			#endif
			return
		}
		
		let thumb = UIButton(frame: view.frame)
		let size = CGSize(width: view.frame.width, height: view.frame.height)
		
		UIGraphicsBeginImageContextWithOptions(size, true, 0)
		thumbImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
		
		// if play icon exists
		if let play = GMFResources.playerBarPlayLargeButtonImage() {
			let playSize = play.size
			play.draw(in: CGRect(x: (size.width - play.size.width)/2,
			                     y: (size.height - play.size.height)/2,
			                     width: play.size.width,
			                     height: playSize.height))
		}
		
		thumb.setImage(UIGraphicsGetImageFromCurrentImageContext(), for: UIControlState())
		UIGraphicsEndImageContext()
		
		thumb.addTarget(self, action: #selector(thumbTouchHandler), for: .touchUpInside)
		
		_thumb = thumb
		
		view.addSubview(thumb)
		view.setNeedsLayout()
	}
	
	private func decideUrl() -> URL? {
		var urlOpt = media.url
		
		// outputs
		if let outputs = media.outputs, outputs.count > 0 {
			// assume 0 in case of no default output
			_currentOutput = 0
			urlOpt = outputs[_currentOutput].url
			
			for (k,v) in outputs.enumerated() where v.isDefault {
				_currentOutput = k
				urlOpt = v.url
			}
			
			_hasMultipleOutputs = outputs.count > 1
		}
		
		// final URL
		guard let urlString = urlOpt else { return nil }
		
		return URL(string: urlString)
	}
	
	private func createAsset(_ url: URL?) -> AVURLAsset? {
		guard let url = url else {
			dispatchError(SambaPlayerError.invalidUrl)
			return nil
		}
		
		return AVURLAsset(url: url)
	}
	
	private func loadAsset(_ asset: AVURLAsset?, _ autoPlay: Bool = false) {
		guard let asset = asset,
			let player = _player else { return }
		
		// IMA
		if !media.isAudio, let adUrl = media.adUrl {
			let mediaId = (media as? SambaMediaConfig)?.id ?? ""
			player.loadStream(with: asset, imaTag: "\(adUrl)&vid=[\(mediaId.isEmpty ? "live" : mediaId)]")
		}
		// default
		else {
			_pendingPlay = autoPlay
			player.loadStream(with: asset)
		}
	}
	
	private func reset() {
		stopTimer()
		_player?.player.reset()
	}
	
	private func destroyThumb() {
		guard let thumb = _thumb else { return }
		
		thumb.removeTarget(self, action: #selector(thumbTouchHandler), for: .touchUpInside)
		thumb.removeFromSuperview()
		_thumb = nil
	}
	
	private func destroyInternal() {
		guard let player = _player else { return }
		
		stopTimer()
		player.player.reset()
		detachVC(player)
		NotificationCenter.default.removeObserver(self)
		
		_player = nil
	}
	
	private func dispatchError(_ error: SambaPlayerError) {
		#if DEBUG
		print(error.localizedDescription)
		#endif
		
		_disabled = error.criticality != .minor
		
		DispatchQueue.main.async {
			for delegate in self._delegates { delegate.onError?(error) }
			
			switch error.criticality {
			case .info: fallthrough
			case .recoverable:
				self.showError(error)
			case .critical:
				self.destroy(withError: error)
			default: break
			}
		}
	}
	
	private func showError(_ error: SambaPlayerError) {
		// try to use existing error screen
		if let errorScreen = _errorScreen as? ErrorScreen {
			errorScreen.error = error
			return
		}
		
		let errorScreen = ErrorScreen(error)
		errorScreen.delegate = self
		showScreen(errorScreen, &_errorScreen) 
	}
	
	private func showScreen(_ screen: UIViewController, _ ref: inout UIViewController?, _ parent: UIViewController? = nil) {
		guard ref == nil else { return }
		attachVC(screen, parent)
		ref = screen
	}
	
	private func destroyScreen(_ ref: inout UIViewController?) {
		guard let screen = ref else { return }
		detachVC(screen)
		ref = nil
	}
	
	/**
	Tries to restart the playback
	
	- parameter url: The URL to retry if provided
	*/
	private func retry(_ url: String? = nil) {
		if let url = url ?? (_currentOutput != -1 && _currentOutput < media.outputs?.count ?? 0 ?
			media.outputs?[_currentOutput].url : media.url) {
			// try to connect again
			loadAsset(createAsset(URL(string: url)), true)
		}
		else {
			dispatchError(SambaPlayerError.invalidUrl)
		}
	}
	
	// MARK: Handlers
	
	func onRetryTouch() {
		retry()
	}
	
	@objc private func thumbTouchHandler() {
		play()
	}
	
	@objc private func playbackStateHandler() {
		guard let player = _player else { return }
		
		let lastState = _state
		
		_state = player.playbackState()
		
		#if DEBUG
		print("state: \(lastState) => \(_state)")
		#endif
		
		switch _state {
		case kGMFPlayerStateReadyToPlay:
			for delegate in _delegates { delegate.onLoad?() }
			
			if _pendingPlay {
				play()
				_pendingPlay = false
			}
			
		case kGMFPlayerStatePlaying:
			if !_hasStarted {
				_hasStarted = true
				for delegate in _delegates { delegate.onStart?() }
			}
			
			if !player.isUserScrubbing && lastState != kGMFPlayerStateSeeking {
				for delegate in _delegates { delegate.onResume?() }
			}
			
			startTimer()
			
		case kGMFPlayerStatePaused:
			stopTimer()
			
			if _stopping { _stopping = false }
			else if lastState != kGMFPlayerStateSeeking {
				if !player.isUserScrubbing {
					for delegate in _delegates { delegate.onPause?() }
				}
			}
			// when paused seek dispatch extra progress event to update external infos
			else { progressEventHandler() }
		
		case kGMFPlayerStateFinished:
			stopTimer()
			for delegate in _delegates { delegate.onFinish?() }
		
		case kGMFPlayerStateError:
			_errorManager?.handle()
			
		default: break
		}
	}
	
	private class ErrorManager : SambaPlayerDelegate {
		
		private let player: SambaPlayer
		private var timer: Timer?
		private var currentBackupIndex = 0
		private var currentRetryIndex = 0
		private var secs = 0
		private var hasError = false
		private var currentPosition: Float = 0
		
		init(_ player: SambaPlayer) {
			self.player = player
			player.delegate = self
		}
		
		func handle() {
			hasError = true
			
			guard let playerInternal = player._player,
				let media = player.media as? SambaMediaConfig,
				playerInternal.player != nil else {
				player.dispatchError(SambaPlayerError.playerNotLoaded)
				return
			}
			
			let error = playerInternal.player.error != nil ? playerInternal.player.error as? NSError : nil
			let code = error?.code ?? SambaPlayerError.unknown.code
			var msg = "Ocorreu um erro! Por favor, tente novamente."
			var type = SambaPlayerErrorCriticality.recoverable
			
			// no network/internet connection
			if code == NSURLErrorNotConnectedToInternet || code == -11853 {
				if currentRetryIndex < media.retriesTotal {
					currentRetryIndex += 1
					secs = 8
					msg = ""
					type = .info
					
					DispatchQueue.main.async {
						self.player.stop()
						self.retryHandler()
					}
					
					timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(retryHandler), userInfo: nil, repeats: true)
					return
				}
			}
			// URL not found (or server unreachable)
			else if currentBackupIndex < media.backupUrls.count {
				let url = player.media.backupUrls[currentBackupIndex]
				
				msg = "Conectando..."
				
				DispatchQueue.main.async {
					self.player.reset()
					self.player.retry(url)
					self.currentBackupIndex += 1
				}
			}
			// all atempts have failed
			else { type = .critical }
			
			player.dispatchError(SambaPlayerError(code, msg, type, error))
			
		}
		
		func onLoad() {
			reset()
		}
		
		func onStart() {
			reset()
		}
		
		func onResume() {
			reset()
		}
		
		func onProgress() {
			guard !hasError && player.currentTime > 0 else { return }
			currentPosition = player.currentTime
		}
		
		private func reset() {
			guard hasError else { return }
			
			hasError = false
			currentRetryIndex = 0;
			
			if !player.media.isLive && currentPosition > 0 {
				player.seek(currentPosition)
				currentPosition = 0
			}
			
			player.destroyScreen(&player._errorScreen)
		}
		
		@objc private func retryHandler() {
			// count got to the end
			if secs == 0 {
				timer?.invalidate()
				player.retry()
			}
			
			player.dispatchError(SambaPlayerError.unknown.setValues(secs > 0 ? "Reconectando em \(secs)s" : "Conectando...", .info))
			
			secs -= 1
		}
	}
	
	@objc private func progressEventHandler() {
		for delegate in _delegates { delegate.onProgress?() }
	}
	
	@objc private func fullscreenTouchHandler() {
		UIDevice.current.setValue(_isFullscreen ? UIInterfaceOrientation.portrait.rawValue :
			UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
	}
	
	@objc private func hdTouchHandler() {
		guard let outputs = media.outputs else { return }
		
		showMenu(ModalMenu(sambaPlayer: self,
		                   options: outputs.map { $0.label },
		                   title: "Qualidade",
		                   onSelect: { self.switchOutput($0) },
		                   selectedIndex: _currentOutput))
	}
	
	@objc private func captionsTouchHandler() {
		guard let captions = media.captions,
			let screen = _captionsScreen as? CaptionsScreen else { return }
		
		showMenu(ModalMenu(sambaPlayer: self,
		                   options: captions.map { $0.label },
		                   title: "Legendas",
		                   onSelect: { self.changeCaption($0) },
		                   selectedIndex: screen.currentIndex))
	}
	
	private func attachVC(_ vc: UIViewController, _ vcParent: UIViewController? = nil) {
		let p: UIViewController = vcParent ?? self
		
		DispatchQueue.main.async {
			p.addChildViewController(vc)
			vc.didMove(toParentViewController: p)
			vc.view.frame = p.view.frame
			p.view.addSubview(vc.view)
			p.view.setNeedsDisplay()
		}
	}
	
	private func detachVC(_ vc: UIViewController, _ vcParent: UIViewController? = nil, _ animated: Bool = true, callback: (() -> Void)? = nil) {
		DispatchQueue.main.async {
			if vc.parent != (vcParent ?? self) {
				vc.dismiss(animated: animated, completion: callback)
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
		_progressTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(progressEventHandler), userInfo: nil, repeats: true)
	}
	
	private func stopTimer() {
		_progressTimer.invalidate()
	}
	
	private class FakeListener : NSObject, SambaPlayerDelegate {
		func onLoad() {}
		func onStart() {}
		func onResume() {}
		func onPause() {}
		func onProgress() {}
		func onFinish() {}
		func onDestroy() {}
		func onError(_ error: SambaPlayerError) {}
	}
}

/**
Player error list
*/
@objc public class SambaPlayerError : NSObject, Error {
	/// URL format is invalid
	public static let invalidUrl = SambaPlayerError(1, "Invalid URL format", .critical)
	/// Some error occurred when creating internal player
	public static let creatingPlayer = SambaPlayerError(2, "Error creating player", .critical)
	/// Trying to play a secure media on a rooted device
	public static let rootedDevice = SambaPlayerError(3, "Specified media cannot play on a rooted device", .critical)
	/// Trying to access an internal player instance that's not loaded yet
	public static let playerNotLoaded = SambaPlayerError(4, "Player is not loaded", .critical)
	/// Unknown error
	public static let unknown = SambaPlayerError(-1, "Unknown error", .critical)
	
	/// The error code
	public let code: Int
	/// Whether error should destroy player or not
	public var criticality: SambaPlayerErrorCriticality
	/// The error message
	public var message: String
	/// The error cause
	public var cause: Error?
	
	/**
	Creates a new error entity
	
	- parameter code: The error code
	- parameter message: The error message
	- parameter critical: Whether error should destroy player or not
	- parameter cause: The error cause
	*/
	public init(_ code: Int, _ message: String = "", _ criticality: SambaPlayerErrorCriticality = .minor,
	            _ cause: Error? = nil) {
		self.code = code
		self.message = message
		self.criticality = criticality
		self.cause = cause
	}

	/// Retrieves the error description
	public var localizedDescription: String {
		return message
	}
	
	/**
	Convenience method that customizes data of the current error and returns it
	
	- parameter message: The message to be replaced
	- parameter critical: Whether error should destroy player or not
	- parameter cause: The error cause
	- returns: The current error
	*/
	public func setValues(_ message: String = "", _ criticality: SambaPlayerErrorCriticality? = nil, _ cause: Error? = nil) -> SambaPlayerError {
		self.message = message
		self.criticality = criticality ?? self.criticality
		self.cause = cause
		return self
	}
}

/// Defines the criticality of an error, whether to destroy the player or not.
@objc public enum SambaPlayerErrorCriticality : Int {
	case minor, info, recoverable, critical
}

/// Listens to player events
@objc public protocol SambaPlayerDelegate {
	/// Fired up when player is loaded
	@objc optional func onLoad()
	
	/// Fired up when player is started
	@objc optional func onStart()
	
	/// Fired up when player is resumed ( from paused to play )
	@objc optional func onResume()
	
	/// Fired up when player is paused
	@objc optional func onPause()
	
	/// Fired up when player is playing ( fired each second of playing )
	@objc optional func onProgress()
	
	/// Fired up when player is finished
	@objc optional func onFinish()
	
	/// Fired up when player is destroyed
	@objc optional func onDestroy()
	
	/// Fired up when some error occurs
	@objc optional func onError(_ error: SambaPlayerError)
}
