//
//  MediaListViewControlller.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/3/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import AVKit

class MediaListViewController : UITableViewController {
	
	@IBOutlet weak var liveToggleButton: UIButton!
	@IBOutlet weak var dfpToggleButton: UIButton!
	@IBOutlet var dfpTextField: UITextField!
	
	private var mediaList = [MediaInfo]()
	private let defaultDfp: String = "4xtfj"
	private var dfpActive: Bool = false
	private var liveActive: Bool = false
	
	override func viewDidLoad() {
		self.tableView.backgroundColor = UIColor.clearColor()
		makeInitialRequests()
		
		//Button dfp
		let dfpIcon = dfpToggleButton.currentBackgroundImage?.tintPhoto(UIColor.lightGrayColor())
		dfpToggleButton.setImage(dfpIcon, forState: UIControlState.Normal)
		
		//Button live
		let liveIcon = liveToggleButton.currentBackgroundImage?.tintPhoto(UIColor.lightGrayColor())
		liveToggleButton.setImage(liveIcon, forState: UIControlState.Normal)
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier != "ListItemToDetail" { return }
		
		(segue.destinationViewController as! PlayerViewController).mediaInfo = mediaList[(tableView.indexPathForSelectedRow?.row)!]
	}
	
	override func tableView(tableView: UITableView?, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "MediaListTableViewCell"
		let cell = tableView!.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! MediaListTableViewCell
		
		let media = mediaList[indexPath.row]
		
		cell.mediaTitle.text = media.title
        cell.mediaDesc.text = media.description ?? ""
		
		cell.contentView.backgroundColor = UIColor(indexPath.row & 1 == 0 ? 0xEEEEEE : 0xFFFFFF)

        load_image(media.thumb, cell: cell)

		return cell
	}
    
    func load_image(urlString:String, cell:MediaListTableViewCell) {
        
        let imgURL: NSURL = NSURL(string: urlString)!
        let request: NSURLRequest = NSURLRequest(URL: imgURL)
    
        NSURLConnection.sendAsynchronousRequest(
            request, queue: NSOperationQueue.mainQueue(),
            completionHandler: {(response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                if error == nil {
                    cell.mediaThumb?.image = UIImage(data: data!)
                }
        })
        
    }
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return mediaList.count
	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
	}
	
	private func makeInitialRequests() {
		requestMediaSet([String.init(4421), String.init(4460)])
	}
	
	private func requestMediaSet(pids:[String]) {
		var i = 0

		func request() {
			let pid = pids[i]
			let url = "\(Helpers.settings["svapi_endpoint"]!)medias?access_token=\(Helpers.settings["svapi_token"]!)&pid=\(pid)&published=true"
			
			Helpers.requestURLJson(url) { json in
				guard let json = json else { return }
				
				for jsonNode in json {
					var isAudio = false
					
					// skip non video or audio media
					switch (jsonNode["qualifier"] as? String ?? "").lowercaseString {
					case "audio":
						isAudio = true
						fallthrough
					case "video": break
					default: continue
					}
					
					var thumbUrl = ""

					if let thumbs = jsonNode["thumbs"] as? [AnyObject] {
						for thumb in thumbs {
							if let url = thumb["url"] as? String {
								thumbUrl = url
							}
						}
					}

					let m = MediaInfo(
						title: jsonNode["title"] as? String ?? "",
						thumb: (!isAudio) ? thumbUrl: "https://cdn4.iconfinder.com/data/icons/defaulticon/icons/png/256x256/media-volume-2.png",
						projectHash: Helpers.settings["pid_" + pid]!,
						mediaId: jsonNode["id"] as? String ?? "",
						isAudio: isAudio
					)
					
					self.mediaList.append(m)
				}
				
				i += 1
				
				if i == pids.count {
					self.tableView.reloadData()
					return
				}
				
				request()
				return
			}
		}
		
		if i < pids.count {
			request()
		}
	}
	
	private func requestAds(hash: String) {
		let url = "\(Helpers.settings["myjson_endpoint"]!)\(hash)"
		
		Helpers.requestURLJson(url) { json in
			guard let json = json else {
				self.enableDfpButton(false)
				return
			}
			
			var dfpIndex = 0
			
			for media in self.mediaList where !media.isAudio {
				dfpIndex = dfpIndex < json.count - 1 ? dfpIndex + 1 : 0
				
				media.description = json[dfpIndex]["name"] as? String
				media.mediaAd = json[dfpIndex]["url"] as? String
			}
			
			self.tableView.reloadData()
			
		}
	}
	
	private func enableDfpButton(state: Bool) {
		guard state != dfpActive else { return }
		
		// disabling ads
		if !state {
			for media in mediaList {
				media.description = nil
				media.mediaAd = nil
			}
			
			self.tableView.reloadData()
		}
		
		let dfpIcon = dfpToggleButton.currentBackgroundImage?.tintPhoto(state ? UIColor.clearColor() : UIColor.lightGrayColor())
		dfpToggleButton.setImage(dfpIcon, forState: UIControlState.Normal)
		
		dfpActive = state
	}
	
	private func enableLiveButton(state: Bool) {
		guard state != liveActive else { return }
		
		mediaList = [MediaInfo]()
		if(!state) {
			makeInitialRequests()
			enableDfpButton(false)
		}
		
		let liveIcon = liveToggleButton.currentBackgroundImage?.tintPhoto(state ? UIColor.clearColor() : UIColor.lightGrayColor())
		liveToggleButton.setImage(liveIcon, forState: UIControlState.Normal)
		
		liveActive = state
	}
	
	//Fill live
	private func fillLive() {
		let thumbURL = "http://www.impactmobile.com/files/2012/09/icon64-broadcasts.png"
		let ph = "bc6a17435f3f389f37a514c171039b75"
		
		let m = MediaInfo(
			title: "Live SBT (HLS)",
			thumb:  thumbURL,
			projectHash: ph,
			mediaId: nil,
			isAudio: false,
			mediaURL: "http://gbbrlive2.sambatech.com.br/liveevent/sbt3_8fcdc5f0f8df8d4de56b22a2c6660470/livestream/manifest.m3u8"
		)
		
		self.mediaList.append(m)
		
		let m1 = MediaInfo(
			title: "Live VEVO (HLS)",
			thumb: thumbURL,
			projectHash: ph,
			mediaId: nil,
			isAudio: false,
			mediaURL: "http://vevoplaylist-live.hls.adaptive.level3.net/vevo/ch1/appleman.m3u8"
		)
		
		self.mediaList.append(m1)
		
		let m2 = MediaInfo(
			title: "Live Denmark channel (HLS)",
			thumb: thumbURL,
			projectHash: ph,
			mediaId: nil,
			isAudio: false,
			mediaURL: "http://itv08.digizuite.dk/tv2b/ngrp:ch1_all/playlist.m3u8"
		)
		
		self.mediaList.append(m2)
		
		let m3 = MediaInfo(
			title: "Live Denmark channel (HDS: erro!)",
			thumb: thumbURL,
			projectHash: ph,
			mediaId: nil,
			isAudio: false,
			mediaURL: "http://itv08.digizuite.dk/tv2b/ngrp:ch1_all/manifest.f4m"
		)
		
		self.mediaList.append(m3)
		
		let m4 = MediaInfo(
			title: "Tv Diário",
			thumb: thumbURL,
			projectHash: ph,
			mediaId: nil,
			isAudio: false,
			mediaURL: "http://slrp.sambavideos.sambatech.com/liveevent/tvdiario_7a683b067e5eee5c8d45e1e1883f69b9/livestream/playlist.m3u8"
		)
		
		self.mediaList.append(m4)
		
		let m5 = MediaInfo(title: "Live áudio",
		                   thumb: "https://cdn4.iconfinder.com/data/icons/defaulticon/icons/png/256x256/media-volume-2.png",
		                   projectHash: ph,
		                   mediaId: nil,
		                  mediaURL: "http://slrp.sambavideos.sambatech.com/radio/pajucara4_7fbed8aac5d5d915877e6ec61e3cf0db/livestream/playlist.m3u8",
		                  isLiveAudio: true)
		
		self.mediaList.append(m5)
		
		self.tableView.reloadData()
	}
	
	@IBAction func dfpTapped() {
		enableDfpButton(!dfpActive)
		
		if dfpActive {
			requestAds((dfpTextField.text ?? "").isEmpty ? defaultDfp : dfpTextField.text!)
		}
	}
	
	@IBAction func dfpEditingChanged() {
		enableDfpButton(false)
	}
	
	@IBAction func liveTapped(sender: AnyObject) {
		enableLiveButton(!liveActive)
		
		if liveActive {
			fillLive()
		}
	}
}

class MediaInfo {
	let title:String
	let thumb:String
	let projectHash:String
	let mediaId:String?
	let isAudio:Bool
	var mediaAd:String?
	var description:String?
	let mediaURL:String?
	let isLiveAudio: Bool?
	
	init(title:String, thumb:String, projectHash:String, mediaId:String? = nil, isAudio:Bool = false, description:String? = nil, mediaAd:String? = nil, mediaURL:String? = nil, isLiveAudio: Bool? = false) {
		self.title = title
		self.thumb = thumb
		self.projectHash = projectHash
		self.mediaId = mediaId
		self.isAudio = isAudio
		self.description = description
		self.mediaAd = mediaAd
		self.mediaURL = mediaURL
		self.isLiveAudio = isLiveAudio
	}
}
