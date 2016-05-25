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
		player.view.removeFromSuperview()
		player.removeFromParentViewController()
		NSNotificationCenter.defaultCenter().removeObserver(self)
		
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
		
		gmf.videoTitle = media.title
		
		//http://gbbrpvbps-sambavideos.akamaized.net/account/37/2/2015-11-05/video/cb7a5d7441741d8bcb29abc6521d9a85/marina_360p.mp4
		gmf.loadStreamWithURL(NSURL(string: url))
		
		addChildViewController(gmf)
		gmf.didMoveToParentViewController(self)
		gmf.view.frame = view.frame
		view.addSubview(gmf.view)
		view.setNeedsDisplay()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playbackStateHandler:"), name: kGMFPlayerPlaybackStateDidChangeNotification, object: gmf)
		
		var theme = colorWithHexString(media.theme)
		
		gmf.controlTintColor = theme
		
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
	
	//Hex to UIColor
	private func colorWithHexString (hex:String) -> UIColor {
		var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
		
		if (cString.hasPrefix("#")) {
			cString = (cString as NSString).substringFromIndex(1)
		}
		
		if (cString.characters.count != 6) {
			return UIColor.grayColor()
		}
		
		let rString = (cString as NSString).substringToIndex(2)
		let gString = ((cString as NSString).substringFromIndex(2) as NSString).substringToIndex(2)
		let bString = ((cString as NSString).substringFromIndex(4) as NSString).substringToIndex(2)
		
		var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
		NSScanner(string: rString).scanHexInt(&r)
		NSScanner(string: gString).scanHexInt(&g)
		NSScanner(string: bString).scanHexInt(&b)
		
		
		return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
	}
	
	private func initIma() {
//		let ima = GMFIMASDKAdService(GMFVideoPlayer: gmf)
//		gmf.registerAdService(ima)
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

extension UIColor {
	// Creates a UIColor from a Hex string.
	convenience init(hexString: String) {
		var cString: String = hexString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
		
		if (cString.hasPrefix("#")) {
			cString = (cString as NSString).substringFromIndex(1)
		}
		
		if (cString.characters.count != 6) {
			self.init(white: 0.5, alpha: 1.0)
		} else {
			let rString: String = (cString as NSString).substringToIndex(2)
			let gString = ((cString as NSString).substringFromIndex(2) as NSString).substringToIndex(2)
			let bString = ((cString as NSString).substringFromIndex(4) as NSString).substringToIndex(2)
			
			var r: CUnsignedInt = 0, g: CUnsignedInt = 0, b: CUnsignedInt = 0;
			NSScanner(string: rString).scanHexInt(&r)
			NSScanner(string: gString).scanHexInt(&g)
			NSScanner(string: bString).scanHexInt(&b)
			
			self.init(red: CGFloat(r) / CGFloat(255.0), green: CGFloat(g) / CGFloat(255.0), blue: CGFloat(b) / CGFloat(255.0), alpha: CGFloat(1))
		}
		
	}
}

