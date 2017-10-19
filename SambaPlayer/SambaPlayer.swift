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
public class SambaPlayer : UIViewController, ErrorScreenDelegate, MenuOptionsDelegate {
	
	private var _player: GMFPlayerViewController?
	private var _parent: UIViewController!
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
	private var _pendingPlay = false
	private var _wasPlayingBeforePause = false
	private var _state = kGMFPlayerStateEmpty
	private var _thumb: UIButton?
	private var _decryptDelegate: AssetLoaderDelegate?
	private var _disabled = false
	private var _errorManager: ErrorManager?
	private var _outputManager: OutputManager?
    private let _rateOutputs: [Float] = [2.0, 1.5, 1.0, 0.5, 0.25]
	
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
		return Float(_player?.totalMediaTime() ?? 0)
	}
	
	/// Outputs available
	public var outputs: [Output] {
		return _outputManager?.menuItems.filter({ $0.label.lowercased() != "auto" }) ?? [Output]()
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
			
			let playerExists = _player != nil
			
			DispatchQueue.main.async {
				// reset playback
				if playerExists,
					let url = self.decideUrl() {
					self.reset()
					self.configUI()
					self.postConfigUI()
					self.retry(url, false)
					self.updateFullscreen(nil, false)
				}
				
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
	public var controlsVisible = true {
		didSet {
			(_player?.playerOverlayView() as? GMFPlayerOverlayView)?.isHidden = !controlsVisible
		}
	}
	
	/// Whether player shoud be fullscreen or not
	public var fullscreen = false {
		didSet {
			UIDevice.current.setValue(self.fullscreen ? UIInterfaceOrientation.landscapeLeft.rawValue :
				UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
		}
	}
	
	/// Sets playback speed (values can vary from -1 to 2)
	public var rate: Float {
		set(value) {
			_player?.player.rate = value
		}
		get { return _player?.player.rate ?? 0 }
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
		_parentView = parentView
		attachVC(self, parentViewController, parentView)
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
		
		if _hasStarted {
			DispatchQueue.main.async { self.destroyThumb() }
			player.play()
		}
		else {
			_pendingPlay = true
		}
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
		_player?.player.seek(toTime: TimeInterval(pos))
    }
	
	/**
	Changes the current output
	
		player.switchOutput(1)
	
	- parameter value: Index of the output, -1 for auto switch.
	*/
	public func switchOutput(_ value: Int) {
		_outputManager?.currentIndex = value + 1
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
		
		reset(false)
		
		if let player = _player {
			detachVC(player, nil, false)
		}
		
		NotificationCenter.default.removeObserver(self)
		_isFullscreen = false
		_player = nil
		
		for delegate in _delegates { delegate.onDestroy?() }
	}
	
	// MARK: Overrides
	
	public override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return .allButUpsideDown
	}
	
	public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		updateFullscreen(size)
	}
	
	private func updateFullscreen(_ size: CGSize? = nil, _ animated: Bool = true, _ forcePortrait: Bool = false) {
		guard _errorScreen == nil, !_fullscreenAnimating,
			let player = _player else { return }
		
		if media.isAudio {
			guard let parentView = _parentView ?? parent?.view else { return }
			var f = player.view.frame
			f.size.width = size?.width ?? parentView.frame.width
			player.view.frame = f
			player.view.setNeedsDisplay()
			return
		}
		
		let callback = {
			self._fullscreenAnimating = false
			
			if let menu = self._currentMenu {
				self.showMenu(menu, true)
			}
            
            self.presentOptionsAlert()
            self.prepareOptionsMenuAfterFullScreen()
		}
		
		let exitFullscreen = {
            self.prepareAlertForFullScreen()
            self.prepareOptionsMenuBeforeFullScreen()
			self._fullscreenAnimating = true
			
			self.detachVC(player, nil, animated) {
				self._isFullscreen = false
				
				player.getControlsView().setMinimizeButtonImage(GMFResources.playerBarMinimizeButtonImage())
				self.attachVC(player)
				callback()
			}
		}
		
		if let menu = _currentMenu {
			hideMenu(menu, true)
		}
		
		if forcePortrait {
			exitFullscreen()
			return
		}
		
		//po "fullscreen=\(_isFullscreen) parent=\(player.parent != nil) landscape=\(UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) landscape.status=\(UIApplication.shared.statusBarOrientation.isLandscape) portrait=\(UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) portrait.status=\(UIApplication.shared.statusBarOrientation.isPortrait)"
		
		let isValidDeviceOrientation = UIDeviceOrientationIsValidInterfaceOrientation(UIDevice.current.orientation)
		
		if _isFullscreen {
			// if UI will change to portrait
			if isValidDeviceOrientation ?
				UIDeviceOrientationIsPortrait(UIDevice.current.orientation) :
				UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation) {
				exitFullscreen()
			}
		}
		// if UI will change to landscape
		else if isValidDeviceOrientation ?
			UIDeviceOrientationIsLandscape(UIDevice.current.orientation) :
			UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
            self.prepareAlertForFullScreen()
            self.prepareOptionsMenuBeforeFullScreen()
			_fullscreenAnimating = true
			_isFullscreen = true
			
			player.getControlsView().setMinimizeButtonImage(GMFResources.playerBarMaximizeButtonImage())
			detachVC(player)
			
			DispatchQueue.main.async {
				self.present(player, animated: animated, completion: callback)
			}
		}
	}
	
	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		guard let parent = parent else {
			fatalError("No parent VC found (null) when adding player to hierarchy (viewDidAppear)")
		}
		
		_parent = parent
		_parentView = _parentView ?? parent.view
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
		
		guard let url = decideUrl(),
			let asset = createAsset(url) else { return }
		
		guard let gmf = GMFPlayerViewController(controlsPadding: CGRect(x: 0, y: 0, width: 0, height: media.isAudio ? 10 : 0),
		                                        andInitedBlock: postConfigUI) else {
			dispatchError(SambaPlayerError.creatingPlayer)
			return
		}
	
		_player = gmf
		_outputManager = OutputManager(self)
		_captionsScreen = CaptionsScreen(player: self)
		
		configUI()
		DispatchQueue.main.async { self.destroyThumb() } // antecipates thumb destroy
		attachVC(gmf, nil, nil) { self.updateFullscreen(nil, false) }
		
		let nc = NotificationCenter.default
		
		nc.addObserver(self, selector: #selector(playbackStateHandler),
		               name: NSNotification.Name.gmfPlayerPlaybackStateDidChange, object: gmf)
		
		nc.addObserver(self, selector: #selector(durationChangedHandler),
		               name: NSNotification.Name.gmfPlayerCurrentTotalTimeDidChange, object: gmf)
		
		nc.addObserver(self, selector: #selector(fullscreenTouchHandler),
		               name: NSNotification.Name.gmfPlayerDidMinimize, object: gmf)
		
		nc.addObserver(self, selector: #selector(hdTouchHandler),
		               name: NSNotification.Name.gmfPlayerDidPressHd, object: gmf)
		
		nc.addObserver(self, selector: #selector(captionsTouchHandler),
		               name: NSNotification.Name.gmfPlayerDidPressCaptions, object: gmf)
		
		// Tracking
		let _ = Tracking(self)
		
		loadAsset(asset, autoPlay)
	}
	
	private func configUI() {
		guard let player = _player else { return }
		
		player.controlTintColor = UIColor(media.theme)
		player.backgroundColor = media.isAudio ? UIColor(0x434343) : UIColor.black
	}
	
	private func postConfigUI() {
		guard let player = _player else { return }
		
        player.removeActionButton(byName: "menuOptions")
        player.removeActionButton(byName: "Live")
		if media.isAudio {
			player.videoTitle = ""
			player.hideBackground()
			player.getControlsView().hideFullscreenButton()
			player.getControlsView().showPlayButton()
			player.getControlsView().hideCaptionsButton()
			(player.playerOverlayView() as! GMFPlayerOverlayView).controlsOnly = true
			player.playerOverlay().autoHideEnabled = false
			player.playerOverlay().controlsHideEnabled = false
		}
		// video only features
		else {
			player.videoTitle = media.title
			player.showBackground()
			player.getControlsView().showFullscreenButton()
			player.getControlsView().hidePlayButton()
			(player.playerOverlayView() as! GMFPlayerOverlayView).enableTopBar()
            (player.playerOverlayView() as! GMFPlayerOverlayView).controlsOnly = false
			player.playerOverlay().autoHideEnabled = true
			player.playerOverlay().controlsHideEnabled = true

			// captions
			if let captionsScreen = _captionsScreen as? CaptionsScreen,
					captionsScreen.hasCaptions {
				if captionsScreen.parent == nil {
					attachVC(captionsScreen, player.playerOverlay())
				}

				player.getControlsView().showCaptionsButton()
			}
			else {
				player.getControlsView().hideCaptionsButton()
			}
		}
		
		if media.isLive {
			player.getControlsView().hideScrubber()
			player.getControlsView().hideTime()
			(player.playerOverlayView() as! GMFPlayerOverlayView).hideBackground()
			(player.playerOverlayView() as! GMFPlayerOverlayView).topBarHideEnabled = false
			(player.playerOverlayView() as! GMFPlayerOverlayView).enableTopBar()
		}
		else {
			player.getControlsView().showScrubber()
			player.getControlsView().showTime()
			(player.playerOverlayView() as! GMFPlayerOverlayView).topBarHideEnabled = true
			
			if media.isAudio {
				(player.playerOverlayView() as! GMFPlayerOverlayView).hideBackground()
				(player.playerOverlayView() as! GMFPlayerOverlayView).disableTopBar()
			}
			else {
				(player.playerOverlayView() as! GMFPlayerOverlayView).showBackground()
				(player.playerOverlayView() as! GMFPlayerOverlayView).enableTopBar()
			}
		}
		
		if !controlsVisible {
			// update setter
			controlsVisible = false
		}
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
		view.setNeedsDisplay()
	}
	
	private func decideUrl() -> URL? {
		var urlOpt = media.url
		
		// outputs
		if let outputs = media.outputs, outputs.count > 0 {
			// assume first output in case of no default
			urlOpt = outputs[0].url
			
			for (_, v) in outputs.enumerated() where v.isDefault {
				urlOpt = v.url
			}
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
		
		let asset = AVURLAsset(url: url)
		
		if let m = media as? SambaMediaConfig,
			let drmRequest = m.drmRequest {
			// must retain a strong reference to it (weak init reference)
			_decryptDelegate = AssetLoaderDelegate(asset: asset, assetName: m.id, drmRequest: drmRequest)
		}
		
		return asset
	}
	
	private func loadAsset(_ asset: AVURLAsset?, _ autoPlay: Bool = false) {
		guard let asset = asset,
			let player = _player else {
			fatalError("Player or asset not found (null) when loading stream!")
		}
		
		// IMA
		if !media.isAudio, let adUrl = media.adUrl {
			let mediaId = (media as? SambaMediaConfig)?.id ?? ""
			player.loadStream(with: asset,
			                  imaTag: "\(adUrl)&vid=[\(mediaId.isEmpty ? "live" : mediaId)]",
				andSettings: media.adsSettings)
		}
		// default
		else {
			_pendingPlay = autoPlay
			player.loadStream(with: asset)
		}
	}
	
	private func reset(_ recoverable: Bool = true) {
		_hasStarted = false
        _optionsAlertSheet = nil
        stop()
		stopTimer()
        destroyOptionsMenu()
		
        _errorManager?.reset()
		if !recoverable {
            _player?.reset()
		}
		
		for delegate in _delegates { delegate.onReset?() }
	}
	
	private func destroyThumb() {
		guard let thumb = _thumb else { return }
		
		thumb.removeTarget(self, action: #selector(thumbTouchHandler), for: .touchUpInside)
		thumb.removeFromSuperview()
		_thumb = nil
		view.setNeedsDisplay()
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
				self.stopTimer()
				self.showError(error)
			
			case .critical:
				self.destroy(withError: error)
			
			default: break
			}
		}
	}
	
	private func showError(_ error: SambaPlayerError) {
		// try to use existing error screen
        _optionsAlertSheet = nil
        destroyOptionsMenu()
		if let errorScreen = _errorScreen as? ErrorScreen {
			errorScreen.error = error
			return
		}
		
		if let menu = _currentMenu {
			hideMenu(menu, true)
		}

		updateFullscreen(nil, false, true)
		
		let errorScreen = ErrorScreen(error)
		errorScreen.delegate = self
		showScreen(errorScreen, &_errorScreen)
	}
	
	private func showScreen(_ screen: UIViewController, _ ref: inout UIViewController?, _ parent: UIViewController? = nil) {
		guard ref == nil else { return }
		attachVC(screen, parent)
		ref = screen
	}
	
	private func destroyScreen(_ ref: inout UIViewController?, callback: (() -> Void)? = nil) {
		guard let screen = ref else {
			callback?()
			return
		}
		
		detachVC(screen, nil, true, callback: callback)
		ref = nil
	}
	
	/**
	Tries to restart the playback
	
	- parameter url: The URL to retry if provided
	*/
	private func retry(_ url: URL? = nil, _ isCurrentMedia: Bool = true) {
		if isCurrentMedia {
			// disable ad
			media.adUrl = nil
		}
		
		if let manager = _outputManager,
			let url = url ??
				URL(string: manager.getMenuItem(manager.currentIndex)?.url.absoluteString ??
				media.url ?? "") {
			// try to connect again
			loadAsset(createAsset(url), isCurrentMedia)
		}
		else {
			dispatchError(SambaPlayerError.invalidUrl)
		}
	}
	
	// MARK: Handlers
	
	func onRetryTouch() {
		dispatchError(SambaPlayerError.unknown.setValues("Conectando...", .info))
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
				DispatchQueue.main.async { self.destroyThumb() }
				player.play()
				_pendingPlay = false
			}
			
		case kGMFPlayerStatePlaying:
			if !_hasStarted {
				_hasStarted = true
				for delegate in _delegates { delegate.onStart?() }
			}
			
			if lastState != kGMFPlayerStateSeeking && !player.isUserScrubbing {
				for delegate in _delegates { delegate.onResume?() }
			}
			
			updateDvrInfo()
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
			else {
				progressEventHandler()
				updateDvrInfo()
			}

		case kGMFPlayerStateFinished:
			stopTimer()
			for delegate in _delegates { delegate.onFinish?() }
		
		case kGMFPlayerStateError:
			_errorManager?.handle()
			
		default: break
		}
	}
	
	@objc private func durationChangedHandler() {
		if media.isDvr && duration > 0 {
			_player?.getControlsView().showScrubber()
		}
	}
	
	@objc private func progressEventHandler() {
		for delegate in _delegates { delegate.onProgress?() }
	}
	
	@objc private func fullscreenTouchHandler() {
		fullscreen = !_isFullscreen
	}
	
	@objc private func hdTouchHandler() {
		guard let manager = _outputManager else { return }
        var actions:[UIAlertAction] = []
        let closure = { (index: Int) in { (action: UIAlertAction!) -> Void in
                self.switchOutput(index)
                self._optionsAlertSheet = nil
                self.destroyOptionsMenu()
            }
        }
        for (index, item) in manager.menuItems.enumerated() {
            let action = UIAlertAction.init(title: item.label, style: .default, handler: closure(index))
            actions.append(action)
        }
        self.createAlert(with: actions, and: "Qualidade")
	}
    
    @objc private func rateTouchHandler() {
        var actions:[UIAlertAction] = []
        let closure = { (rate: Float) in { (action: UIAlertAction!) -> Void in
                self.rate = rate
                self._optionsAlertSheet = nil
                self.destroyOptionsMenu()
            }
        }
        for rate in _rateOutputs {
            let action = UIAlertAction.init(title: "\(rate) x", style: .default, handler: closure(rate))
            actions.append(action)
        }
        self.createAlert(with: actions, and: "Velocidade")
    }
	
	@objc private func captionsTouchHandler() {
		guard let captions = media.captions,
			let screen = _captionsScreen as? CaptionsScreen else { return }
		
		showMenu(ModalMenu(sambaPlayer: self,
		                   items: captions.map { $0.label },
		                   title: "Legendas",
		                   onSelect: { self.changeCaption($0) },
		                   selectedIndex: screen.currentIndex))
	}
	
	@objc private func realtimeButtonHandler() {
		seek(duration)
		play()
	}
	
	private func updateDvrInfo() {
		// if DVR media, hide Live indicator if current time is below a tolerance
		if media.isDvr {
			(_player?.playerOverlayView() as? GMFPlayerOverlayView)?.getActionButton("Live")
				.setImage(currentTime < duration - 45 ? GMFResources.playerTitleRealtimeIcon() : GMFResources.playerTitleLiveIcon(),
				          for: .normal)
		}
	}
	
	private func attachVC(_ target: UIViewController, _ parent: UIViewController? = nil, _ parentView: UIView? = nil, callback: (() -> Void)? = nil) {
		let parent: UIViewController = parent ?? self
		
		guard let parentView = parentView ?? parent.view else {
			fatalError("No view found (null) when attaching \(target) to parent \(parent)!")
		}
		
		DispatchQueue.main.async {
			parent.addChildViewController(target)
			target.didMove(toParentViewController: parent)
            target.view.frame = parentView.bounds
			parentView.addSubview(target.view)
			
			// always try to keep error screen above all views
			if let errorView = self._errorScreen?.view,
				let errorParentView = errorView.superview {
				errorParentView.bringSubview(toFront: errorView)
			}
			
			parentView.setNeedsDisplay()
			callback?()
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
	
	// MARK: Managers
	
	/// Represents an output menu item
	public struct Output : Hashable {
		public var hashValue: Int {
			return Int(label.substring(to: label.index(before: label.endIndex))) ?? 0
		}
		
		public let url: URL, label: String
		
		public static func ==(lhs: Output, rhs: Output) -> Bool {
			return lhs.label == rhs.label && lhs.url.absoluteString == rhs.url.absoluteString
		}
	}
    
    //alert control methods
    private var _optionsAlertSheet: UIAlertController? {
        willSet {
            if newValue == nil {
                DispatchQueue.main.async {
                    self._optionsAlertSheet?.dismiss(animated: false, completion: nil)
                }
            }
        }
        didSet {
            presentOptionsAlert(true)
        }
    }
    
    private func createAlert(with actions: [UIAlertAction], and title: String) {
        let alert = UIAlertController.init(title: title, message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction.init(title: "Cancelar", style: .cancel, handler: { (alertAction: UIAlertAction!) in
            alert.dismiss(animated: true, completion: nil)
            self._optionsAlertSheet = nil
            self.destroyOptionsMenu()
        })
        for action in actions {
            alert.addAction(action)
        }
        alert.addAction(cancel)
        _optionsAlertSheet = alert
    }
    
    private func prepareAlertForFullScreen() {
        DispatchQueue.main.async {
            self._optionsAlertSheet?.dismiss(animated: false, completion: nil)
        }
    }
    
    private func presentOptionsAlert(_ animated: Bool = false) {
        guard let alert = _optionsAlertSheet else {
            return
        }
        DispatchQueue.main.async {
            alert.dismiss(animated: false, completion: nil)
            if let currentVC = self._isFullscreen ? self._player : self.parent {
                if let popoverController = alert.popoverPresentationController {
                        popoverController.sourceView = currentVC.view
                        popoverController.permittedArrowDirections = []
                        popoverController.sourceRect = CGRect(x: currentVC.view.bounds.midX, y: currentVC.view.bounds.midY, width: 0, height: 0)
                }
                currentVC.present(alert, animated: animated, completion: nil)
            }
        }
    }
    
    //options menu methods
    
    private var _optionsMenu: UIViewController? {
        didSet {
            (_optionsMenu as? OptionsMenuView)?.delegate = self
        }
    }
    
    @objc private func createOptionsMenu() {
        var options = MenuOptions.all
        if _outputManager?.menuItems.count ?? 0 > 2 {
            if media.isLive {
                options = .qualityOnly
            }
        } else {
            options = media.isLive ? .none : .speedOnly
        }
        let optionsMenu = OptionsMenuView.init(withOptions: options)
        optionsMenu.options = options
        showScreen(optionsMenu, &_optionsMenu, _isFullscreen ? _player : nil)
        _player?.playerOverlay().hidePlayerControls(animated: true)
    }
    
    private func destroyOptionsMenu() {
        guard let optionsMenu = _optionsMenu else {
            return
        }
        detachVC(optionsMenu, _isFullscreen ? _player : nil)
        _optionsMenu = nil
    }
    
    func prepareOptionsMenuAfterFullScreen() {
        guard let optionsMenu = _optionsMenu else {
            return
        }
        attachVC(optionsMenu, _isFullscreen ? _player : nil)
        _player?.playerOverlay().hidePlayerControls(animated: true)
    }
    
    func prepareOptionsMenuBeforeFullScreen() {
        guard let optionsMenu = _optionsMenu else {
            return
        }
        detachVC(optionsMenu, _isFullscreen ? _player : nil)
    }
    
    func didTouchQuality(){
        self.hdTouchHandler()
    }
    
    func didTouchSpeed(){
        self.rateTouchHandler()
    }
    
    func didTouchClose(){
        destroyOptionsMenu()
    }
    
    func configureTopBar(outputsCount: Int){
        if media.isAudio {
            _player?.removeActionButton(byName: "menuOptions")
            _player?.removeActionButton(byName: "Live")
        } else {
            if outputsCount > 2 || !media.isLive {
                _player?.addActionButton(with: GMFResources.playerTopBarMenuImage(), name: "menuOptions", target: self, selector: #selector(createOptionsMenu))
            } else {
                _player?.removeActionButton(byName: "menuOptions")
            }
            if media.isLive {
                _player?.addActionButton(with: GMFResources.playerTitleLiveIcon(), name:"Live", target:self, selector:#selector(realtimeButtonHandler))
            } else {
                _player?.removeActionButton(byName: "Live")
            }
        }
    }
	
	private class OutputManager : SambaPlayerDelegate {
		
		private let player: SambaPlayer
		private var url: URL?
		private var item: AVPlayerItem?
		
		init(_ player: SambaPlayer) {
			self.player = player
			player.delegate = self
		}
		
		var currentIndex = 0 {
			willSet {
				guard item != nil, newValue != currentIndex,
					let menuItem = getMenuItem(newValue) else { return }
				
				player._player?.player.switch(player.createAsset(menuItem.url))
			}
		}
		
		func getMenuItem(_ index: Int) -> Output? {
			return index > -1 && index < menuItems.count ?
				menuItems[index] : nil
		}
		
		// PLAYER DELEGATE
		
		var menuItems = [Output]()
		
        func onLoad() {
            currentIndex = 0
            item = player._player?.player.player.currentItem
            url = (item?.asset as? AVURLAsset)?.url
            menuItems = extract()
            self.player.configureTopBar(outputsCount: self.menuItems.count)
        }
        
		func onReset() {
			url = nil
			item = nil
			menuItems = [Output]()
		}
		
		private func extract() -> [Output]  {
			guard let url = url,
				let text = try? String(contentsOf: url, encoding: .utf8)
				else { return [Output]() }
			
			let baseUrl = url.absoluteString.replacingOccurrences(of: "[\\w\\.]+\\?.+", with: "", options: .regularExpression)
			var outputs = Set<Output>()
			var label: String?
			
			outputs.insert(Output(url: url, label: "Auto"))
			
			for line in Helpers.matchesForRegexInText("[^\\r\\n]+", text: text) {
				if line.hasPrefix("#EXT-X-STREAM-INF") {
					if let range = line.range(of: "RESOLUTION\\=[^\\,\\r\\n]+", options: .regularExpression) ??
						line.range(of: "BANDWIDTH\\=\\d+", options: .regularExpression) {
						
						let kv = line.substring(with: range)
						
						if let rangeKv = kv.range(of: "\\d+$", options: .regularExpression),
							let n = Int(kv.substring(with: rangeKv)) {
							
							label = "\(kv.contains("x") ? "\(n)p" : "\(n/1000)k")"
						}
					}
				}
				else if let labelString = label,
					line.hasSuffix(".m3u8"),
					let url = URL(string: line.hasPrefix("http") ? line : baseUrl + line) {
					
					outputs.insert(Output(url: url, label: labelString))
					label = nil
				}
			}
			
			return outputs.sorted(by: { $0.hashValue < $1.hashValue })
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
		private var error: NSError?
		private var code = SambaPlayerError.unknown.code
		private var type = SambaPlayerErrorCriticality.recoverable
		
		init(_ player: SambaPlayer) {
			self.player = player
			player.delegate = self
		}
		
		func handle() {
			hasError = true
			
			guard !(timer?.isValid ?? false) else { return }
			
			guard let playerInternal = player._player,
				let media = player.media as? SambaMediaConfig,
				playerInternal.player != nil else {
					player.dispatchError(SambaPlayerError.playerNotLoaded)
					return
			}
			
			error = playerInternal.player.error != nil ? playerInternal.player.error as NSError : nil
			code = error?.code ?? SambaPlayerError.unknown.code
			
			var msg = "Ocorreu um erro! Tente novamente."
			
			type = .recoverable
			
			switch code {
			// unauthorized DRM content
			//case -11800 where media.drmRequest != nil: fallthrough
			case -11833: // actual error: #EXT-X-KEY: invalid KEYFORMAT
				type = .critical
				msg = "Você não tem permissão para \(media.isAudio ? "ouvir este áudio" : "assistir este vídeo")."
				
			// cannot parse
			case -11853: fallthrough
			// no network/internet connection
			case -11800: fallthrough
			case NSURLErrorNotConnectedToInternet:
				guard currentRetryIndex < media.retriesTotal else { break }
				
				currentRetryIndex += 1
				secs = 8
				type = .info
				msg = ""
				
				DispatchQueue.main.async {
					self.player.stop()
					self.retryHandler()
					self.timer?.invalidate()
					self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.retryHandler), userInfo: nil, repeats: true)
				}
				return
			
			// URL not found (or server unreachable)
			default:
				if currentBackupIndex < media.backupUrls.count {
					let url = URL(string: player.media.backupUrls[currentBackupIndex])
					
					currentBackupIndex += 1
					player.retry(url)
					return
				}
				// all attempts have failed
				else { type = .critical }
			}
			
			player.dispatchError(SambaPlayerError(code, msg, type, error))
			
		}
		
		func reset() {
			timer?.invalidate()
			
			hasError = false
			currentRetryIndex = 0
			currentPosition = 0
			player._disabled = false
			
			player.destroyScreen(&player._errorScreen) {
				self.player.updateFullscreen(nil, false)
			}
		}
		
		func onLoad() {
			recover()
		}
		
		func onStart() {
			recover()
		}
		
		func onResume() {
			recover()
		}
		
		func onProgress() {
			guard !hasError && player.currentTime > 0 else { return }
			currentPosition = player.currentTime
		}
		
		func onDestroy() {
			timer?.invalidate()
		}
		
		private func recover() {
			guard hasError else { return }
			
			if !player.media.isLive && currentPosition > 0 {
				player.seek(currentPosition)
				currentPosition = 0
			}
			
			reset()
		}
		
		@objc private func retryHandler() {
			// count got to the end
			if secs <= 0 {
				timer?.invalidate()
				player.retry()
			}
			
			player.dispatchError(SambaPlayerError(code, secs > 0 ? "Reconectando em \(secs)s" : "Conectando...", .info, error))
			
			secs -= 1
		}
	}
	
	private class FakeListener : NSObject, SambaPlayerDelegate {
		func onLoad() {}
		func onStart() {}
		func onResume() {}
		func onPause() {}
		func onProgress() {}
		func onFinish() {}
		func onReset() {}
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
	public var cause: NSError?
	
	/**
	Creates a new error entity
	
	- parameter code: The error code
	- parameter message: The error message
	- parameter critical: Whether error should destroy player or not
	- parameter cause: The error cause
	*/
	public init(_ code: Int, _ message: String = "", _ criticality: SambaPlayerErrorCriticality = .minor,
	            _ cause: NSError? = nil) {
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
	public func setValues(_ message: String = "", _ criticality: SambaPlayerErrorCriticality? = nil, _ cause: NSError? = nil) -> SambaPlayerError {
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
	
	/// Fired up when player is reset
	@objc optional func onReset()
	
	/// Fired up when player is destroyed
	@objc optional func onDestroy()
	
	/// Fired up when some error occurs
	@objc optional func onError(_ error: SambaPlayerError)
}
