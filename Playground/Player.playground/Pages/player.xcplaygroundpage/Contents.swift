import PlaygroundSupport
import UIKit
import AVFoundation

PlaygroundPage.current.needsIndefiniteExecution = true

class PlayerController : UIViewController {
	let player = AVPlayer()
	var resolutions = Set<Int>()
	
	init() {
		super.init(nibName: nil, bundle: nil)
		
		//http://liveabr2.sambatech.com.br/abr/sbtabr_8fcdc5f0f8df8d4de56b22a2c6660470/livestreamabrsbtbkp.m3u8
		//http://slrp.sambavideos.sambatech.com/liveevent/tvdiario_7a683b067e5eee5c8d45e1e1883f69b9/livestream/playlist.m3u8
		//http://rmtvlive-lh.akamaihd.net/i/rmtv_1@154306/master.m3u8
		//http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8
		//http://streaming.almg.gov.br/live/tvalmg2.m3u8
		//http://origin3.live.sambatech.com.br/liveevent_dvr/client_playerHash/livestream/playlist.m3u8?DVR
		//https://pv-s1-sambavideos.akamaized.net/account/219/183/2016-07-27/audio/d4a4f6e493e15c00f4443aaac8b25209/Adele_-_Someone_Like_You.mp3
		let url = URL(string: "http://pvbps-sambavideos.akamaized.net/account/3170/18/2018-06-29/audio/4d075901928e48cb697346d5f5d3981a/LiderCast_113_-_Glaucymar_Peticov.mp3?sts=st=1531344385~exp=1531346065~acl=/*~hmac=eb8e213427fb12793df22ee5d9e988071d0df712a6d793a0f13a162390032363")!
		
		extractOutputs(url)
		
		let asset = AVURLAsset(url: url)
		
		//asset.resourceLoader.setDelegate(AssetInspector(self), queue: DispatchQueue(label: "asdf-dispatchQueue"))
		
		let item = AVPlayerItem(asset: asset)
		
		player.replaceCurrentItem(with: item)
		
		view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 600))
		
		let layer = AVPlayerLayer(player: player)
		
		observe()
		
		NotificationCenter.default.addObserver(self, selector: #selector(onNotification), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
		NotificationCenter.default.addObserver(self, selector: #selector(onNotification), name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: item)
		NotificationCenter.default.addObserver(self, selector: #selector(onNotification), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: item)
		NotificationCenter.default.addObserver(self, selector: #selector(onNotification), name: NSNotification.Name.AVAssetDurationDidChange, object: item)
		NotificationCenter.default.addObserver(self, selector: #selector(onNotification), name: NSNotification.Name.AVAssetTrackSegmentsDidChange, object: item)
		NotificationCenter.default.addObserver(self, selector: #selector(onNotification), name: NSNotification.Name.AVAssetTrackTimeRangeDidChange, object: item)
		NotificationCenter.default.addObserver(self, selector: #selector(onNotification), name: NSNotification.Name.AVAssetTrackTrackAssociationsDidChange, object: item)
		NotificationCenter.default.addObserver(self, selector: #selector(onNotification), name: NSNotification.Name.AVPlayerItemTimeJumped, object: item)
		NotificationCenter.default.addObserver(self, selector: #selector(onNotification), name: NSNotification.Name.AVSampleBufferDisplayLayerFailedToDecode, object: item)
		
		layer.frame = CGRect(x: 0, y: 40, width: view.frame.width/2, height: view.frame.height/2)
		view.layer.addSublayer(layer)
		
		// stack view
		let stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: 0, height: 40))
		stackView.axis = .horizontal
		stackView.distribution = .equalSpacing
		stackView.alignment = .center
		stackView.spacing = 6
		stackView.translatesAutoresizingMaskIntoConstraints = false
		
		// play
		var bt = UIButton()
		bt.setTitle("Play", for: .normal)
		bt.backgroundColor = .green
		bt.addTarget(self, action: #selector(playHandler), for: .touchUpInside)
		stackView.addArrangedSubview(bt)
		
		// stop
		bt = UIButton()
		bt.setTitle("Stop", for: .normal)
		bt.backgroundColor = .red
		bt.addTarget(self, action: #selector(stopHandler), for: .touchUpInside)
		stackView.addArrangedSubview(bt)
		
		// reload
		bt = UIButton()
		bt.setTitle("Reload", for: .normal)
		bt.backgroundColor = .brown
		bt.addTarget(self, action: #selector(reloadHandler), for: .touchUpInside)
		stackView.addArrangedSubview(bt)
		
		// outputs
		let outputButton = UIButton()
		outputButton.setTitle("Outputs", for: .normal)
		outputButton.backgroundColor = .gray
		outputButton.addTarget(self, action: #selector(outputsHandler(_:)), for: .touchUpInside)
		outputButton.isEnabled = false
		stackView.addArrangedSubview(outputButton)
		
		// time
		let timeView = UILabel()
		timeView.text = "0"
		timeView.textColor = .white
		
		Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer: Timer) in
			/*let secs = CMTimeGetSeconds(self.player.currentTime())
			
			if secs > 5 {
				timer.invalidate()
				return
			}*/
			
			timeView.text = "\(Int(CMTimeGetSeconds(item.currentTime())))s"
			
			/*if let range = item.seekableTimeRanges.last?.timeRangeValue {
				print("range.start=\(CMTimeGetSeconds(range.start))", "currentTime=\(CMTimeGetSeconds(item.currentTime()))", "range.duration=\(CMTimeGetSeconds(range.duration))", "range.end=\(CMTimeGetSeconds(range.end))", "item.duration=\(CMTimeGetSeconds(item.duration))")
			}*/
			
			guard let events = item.accessLog()?.events else { return }
			
			if events.count > 1 && !outputButton.isEnabled {
				outputButton.isEnabled = true
				outputButton.backgroundColor = .blue
			}
		}
		
		// seek
		bt = UIButton()
		bt.setTitle("«", for: .normal)
		bt.backgroundColor = .orange
		bt.addTarget(self, action: #selector(bwHandler), for: .touchUpInside)
		stackView.addArrangedSubview(bt)
		
		bt = UIButton()
		bt.setTitle("»", for: .normal)
		bt.backgroundColor = .orange
		bt.addTarget(self, action: #selector(fwHandler), for: .touchUpInside)
		stackView.addArrangedSubview(bt)
		
		stackView.addArrangedSubview(timeView)
		
		view.addSubview(stackView)
		
		player.play()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func extractOutputs(_ url: URL) {
		guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
		
		var labels = Set<String>()
		
		for line in matchesForRegexInText(".+(!?[\\r\\n])", text: text) where line.hasPrefix("#EXT-X-STREAM-INF") {
			if let range = line.range(of: "RESOLUTION\\=[^\\,\\r\\n]+", options: .regularExpression) ??
					line.range(of: "BANDWIDTH\\=\\d+", options: .regularExpression) {
				let kv = line.substring(with: range)

				if let rangeKv = kv.range(of: "\\d+$", options: .regularExpression),
						let n = Int(kv.substring(with: rangeKv)) {
					labels.insert("\(kv.contains("x") ? "\(n)p" : "\(n/1000)k")")
				}
			}
		}
		
		print("outputs:", labels)
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?,
	                           change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let item = player.currentItem else {
			print("no current player item!")
			return
		}
		
		guard let keyPath = keyPath else {
			print("unknown keypath!")
			return
		}
		
		switch keyPath {
		case "presentationSize":
			let res = Int(item.presentationSize.height)
			
			if res > 0 {
				resolutions.insert(res)
				print("# \(keyPath): resolutions=\(resolutions)")
			}
		case "error":
			print("# \(keyPath): error=\(String(describing: player.error)); \(String(describing: item.error))")
		default:
			print("# \(keyPath): status=\(player.status.rawValue) bufferEmpty=\(item.isPlaybackBufferEmpty) keepUp=\(item.isPlaybackLikelyToKeepUp)")
		}
	}
	
	@objc func onNotification(notification: Notification) {
		print("@ \(notification.name.rawValue): \(notification.description) \(String(describing: player.error))")
	}
	
	@objc func playHandler() {
		player.play()
	}
	
	@objc func stopHandler() {
		print("ok")
		player.pause()
		player.seek(to: kCMTimeZero)
	}
	
	@objc func reloadHandler() {
		reloadAsset((player.currentItem?.asset)!)
	}
	
	@objc func fwHandler() {
		seekBy(0)
	}
	
	@objc func bwHandler() {
		seek(0)
	}
	
	private func seekBy(_ deltaTime: Int) {
		guard let item = player.currentItem,
			let range = item.seekableTimeRanges.last?.timeRangeValue
			else { return }
		
		let duration = CMTimeGetSeconds(range.duration)
		
		print("seekBy:", deltaTime, "range.duration=\(duration)", "range.end=\(CMTimeGetSeconds(range.end))")
		seek(duration + Float64(deltaTime))
	}
	
	private func seek(_ time: Float64) {
		guard let item = player.currentItem,
			let range = item.seekableTimeRanges.last?.timeRangeValue
			else { return }
		
		let duration = CMTimeGetSeconds(range.duration)
		let to = min(max(time, 0), duration)
		
		print("seeking:", "\(time)/\(to)", "range.start=\(CMTimeGetSeconds(range.start))", "currentTime=\(CMTimeGetSeconds(item.currentTime()))", "range.duration=\(duration)", "range.end=\(CMTimeGetSeconds(range.end))", "item.duration=\(CMTimeGetSeconds(item.duration))")
		
		player.seek(to: CMTimeAdd(range.start, CMTimeMakeWithSeconds(to, 1)),
		            toleranceBefore: kCMTimeZero,
		            toleranceAfter: kCMTimeZero) { (finished) in
			print("seek end:", "finished=\(finished)", "currentTime=\(CMTimeGetSeconds(item.currentTime()))")
		}
	}
	
	private var outputMenu: UIAlertController? = nil
	
	@objc func outputsHandler(_ sender: UIButton) {
		guard let outputMenu = outputMenu else {
			guard let item = player.currentItem,
				let events = item.accessLog()?.events else { return }
			
			/*print("num tracks: \(item.tracks.count)")
			
			for track in item.tracks {
				let at = track.assetTrack
				print(track.currentVideoFrameRate)
				print(at.commonMetadata)
				print(at.estimatedDataRate)
				print(at.extendedLanguageTag)
				print(at.formatDescriptions)
				print(at.isEnabled)
				print(at.isPlayable)
				print(at.isSelfContained)
				print(at.languageCode)
				print(at.mediaType)
				print(at.metadata)
				print(at.minFrameDuration)
				print(at.naturalSize)
				print(at.naturalTimeScale)
				print(at.nominalFrameRate)
				print(at.preferredTransform)
				print(at.preferredVolume)
				print(at.requiresFrameReordering)
				print(at.segments.count)
				print(at.timeRange)
				print(at.totalSampleDataLength)
				print(at.trackID)
			}*/

			let getOnItemTouch = { (i: Int) -> (UIAlertAction) -> Void in
				return { (action: UIAlertAction) in
					guard i < events.count else { return }
					
					/*print(item.preferredPeakBitRate, events[i].indicatedBitrate)
					item.preferredPeakBitRate = events[i].indicatedBitrate*/
					
					guard let urlString = events[i].uri,
						let url = URL(string: urlString) else { return }
					
					self.reloadAsset(AVURLAsset(url: url))
					
					/*let asset = item.asset
					let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicVisual)
					
					print(asset.availableMediaCharacteristicsWithMediaSelectionOptions)
					print(asset.tracks(withMediaCharacteristic: AVMediaCharacteristicVisual))
					print(group ?? "no group")
					
					if let group = group {
						print(item.selectedMediaOption(in: group) ?? "no group to sel")
					}
					
					print(item.currentMediaSelection)
					print(asset.trackGroups)
					print(asset.track(withTrackID: 1) ?? "no track")*/
				}
			}
			
			let outputMenu = UIAlertController(title: "Outputs", message: "Choose an output", preferredStyle: .actionSheet)
			let resSorted = resolutions.sorted()
			let fillWithRes = resSorted.count == events.count
			
			for (i, event) in events.enumerated() where event.uri != nil {
				outputMenu.addAction(UIAlertAction(title: fillWithRes ? "\(resSorted[i])p" : "\(Int(event.indicatedBitrate/1000.0))k", style: .default, handler: getOnItemTouch(i)))
			}
			
			outputMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			
			self.outputMenu = outputMenu
			outputsHandler(sender)
			return
		}
		
		outputMenu.popoverPresentationController?.sourceView = sender
		outputMenu.popoverPresentationController?.sourceRect = sender.bounds
		
		present(outputMenu, animated: true, completion: nil)
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}
	
	override var shouldAutorotate: Bool {
		return false
	}
	
	private func observe(_ register: Bool = true) {
		guard let item = player.currentItem else { return }
		
		let keyPaths = [
			"status",
			"rate",
			//"tracks",
			"playbackBufferEmpty",
			"playbackLikelyToKeepUp",
			"presentationSize",
			"error"
		]
		
		if register {
			for keyPath in keyPaths {
				item.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
			}
		}
		else {
			for keyPath in keyPaths {
				item.removeObserver(self, forKeyPath: keyPath)
			}
		}
	}
	
	private func reloadAsset(_ asset: AVAsset) {
		DispatchQueue.main.async {
			self.observe(false)
			self.seek(CMTimeGetSeconds(self.player.currentItem!.currentTime()))
			self.player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
			self.observe()
		}
	}
}

class AssetInspector : NSObject, AVAssetResourceLoaderDelegate {
	
	init(_ playerController: PlayerController) {
		
	}
	
	func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
		print("ok")
		return true
	}
	
	func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForResponseTo authenticationChallenge: URLAuthenticationChallenge) -> Bool {
		print("asdf")
		return true
	}
	
	func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
		print("renewal")
		return true
	}
	
	func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
		print("cancel load")
	}
	
	func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel authenticationChallenge: URLAuthenticationChallenge) {
		print("cancel auth")
	}
}

func matchesForRegexInText(_ regex: String!, text: String!) -> [String] {
	do {
		let regex = try NSRegularExpression(pattern: regex, options: [])
		let nsString = text as NSString
		let results = regex.matches(in: text,
		                            options: [], range: NSMakeRange(0, nsString.length))
		
		return results.map { nsString.substring(with: $0.range) }
	}
	catch let error as NSError {
		print("Error: Invalid regex: \(error.localizedDescription)")
	}
	catch {
		print("Error: Some other regex error!")
	}
	
	return []
}

let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
window.rootViewController = PlayerController()
window.makeKeyAndVisible()

PlaygroundPage.current.liveView = window
