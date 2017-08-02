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
			
			// reset playback
			if _player != nil,
				let url = decideUrl() {
				reset()
				configUI()
				retry(url, false)
			}
			
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
		
		for delegate in _delegates { delegate.onDestroy?() }
		
		destroyInternal()
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
		}
		
		let exitFullscreen = {
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
		
		if _isFullscreen {
			// if UI will change to portrait
			if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
				exitFullscreen()
			}
		}
		// if UI will change to landscape
		else if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
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
		                                        andInitedBlock: configUI) else {
			dispatchError(SambaPlayerError.creatingPlayer)
			return
		}
	
		_player = gmf
		
		gmf.videoTitle = media.title
		gmf.controlTintColor = UIColor(media.theme)
		
		if media.isAudio {
			gmf.backgroundColor = UIColor(0x434343)
		}
		else {
			_outputManager = OutputManager(self)
			_captionsScreen = CaptionsScreen(player: self)
		}
		
		destroyThumb()
		attachVC(gmf, nil, nil) { self.updateFullscreen(nil, false) }
		
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
		let _ = Tracking(self)
		
		loadAsset(asset, autoPlay)
	}
	
	private func configUI() {
		guard let player = _player else { return }
		
		if media.isAudio {
			player.hideBackground()
			player.getControlsView().hideFullscreenButton()
			player.getControlsView().showPlayButton()
			(player.playerOverlayView() as! GMFPlayerOverlayView).controlsOnly = true
			player.playerOverlay().autoHideEnabled = false
			player.playerOverlay().controlsHideEnabled = false
			
			if !media.isLive {
				(player.playerOverlayView() as! GMFPlayerOverlayView).hideBackground()
				(player.playerOverlayView() as! GMFPlayerOverlayView).disableTopBar()
			}
		}
		// video only features
		else {
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
			player.getControlsView().hideTotalTime()
			player.addActionButton(with: GMFResources.playerTitleLiveIcon(), name:"Live", target:player, selector:nil)
			(player.playerOverlayView() as! GMFPlayerOverlayView).hideBackground()
			(player.playerOverlayView() as! GMFPlayerOverlayView).topBarHideEnabled = false
		}
		
		if !controlsVisible {
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
		view.setNeedsLayout()
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
	
	private func reset(_ restart: Bool = true) {
		_hasStarted = !restart
		stopTimer()
		_player?.reset()
		
		for delegate in _delegates { delegate.onReset?() }
	}
	
	private func destroyThumb() {
		guard let thumb = _thumb else { return }
		
		thumb.removeTarget(self, action: #selector(thumbTouchHandler), for: .touchUpInside)
		thumb.removeFromSuperview()
		_thumb = nil
	}
	
	private func destroyInternal() {
		guard let player = _player else { return }
		
		reset()
		detachVC(player, nil, false)
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
		guard let screen = ref else { return }
		detachVC(screen, nil, true, callback: callback)
		ref = nil
	}
	
	/**
	Tries to restart the playback
	
	- parameter url: The URL to retry if provided
	*/
	private func retry(_ url: URL? = nil, _ autoPlay: Bool = true) {
		// disable ad
		media.adUrl = nil
		
		if let manager = _outputManager,
			let url = url ??
				URL(string: manager.getMenuItem(manager.currentIndex)?.url.absoluteString ??
				media.url ?? "") {
			// try to connect again
			loadAsset(createAsset(url), autoPlay)
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
	
	@objc private func progressEventHandler() {
		for delegate in _delegates { delegate.onProgress?() }
	}
	
	@objc private func fullscreenTouchHandler() {
		fullscreen = !_isFullscreen
	}
	
	@objc private func hdTouchHandler() {
		guard let manager = _outputManager else { return }
		
		showMenu(ModalMenu(sambaPlayer: self,
		                   items: manager.menuItems.map { $0.label },
		                   title: "Qualidade",
		                   onSelect: { self.switchOutput($0 - 1) },
		                   selectedIndex: manager.currentIndex))
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
			
			if menuItems.count > 2 {
				player._player?.getControlsView().showHdButton()
			}
			else {
				player._player?.getControlsView().hideHdButton()
			}
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
			
			var msg = "Ocorreu um erro! Por favor, tente novamente."
			
			type = .recoverable
			
			switch code {
			// unauthorized DRM content
			//case -11800 where media.drmRequest != nil: fallthrough
			case -11833: // actual error: #EXT-X-KEY: invalid KEYFORMAT
				type = .critical
				msg = "Você não tem permissão para \(media.isAudio ? "ouvir este áudio" : "assistir este vídeo")."
				
			// no network/internet connection
			case -11853: if media.isLive { fallthrough }
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
					
					type = .info
					msg = "Conectando..."
					
					DispatchQueue.main.async {
						self.player.reset(false)
						self.player.retry(url)
						self.currentBackupIndex += 1
					}
				}
					// all atempts have failed
				else { type = .critical }
			}
			
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
		
		func onDestroy() {
			timer?.invalidate()
		}
		
		private func reset() {
			guard hasError else { return }
			
			hasError = false
			currentRetryIndex = 0
			player._disabled = false
			
			if !player.media.isLive && currentPosition > 0 {
				player.seek(currentPosition)
				currentPosition = 0
			}
			
			player.destroyScreen(&player._errorScreen) {
				self.player.updateFullscreen(nil, false)
			}
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
