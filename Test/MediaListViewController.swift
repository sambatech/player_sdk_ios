//
//  MediaListViewControlller.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/3/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import AVKit

class MediaListViewController : UITableViewController {
	
	@IBOutlet weak var dfpToggleButton: UIButton!
	@IBOutlet var dfpTextField: UITextField!
	
	private var mediaList = [MediaInfo]()
	private let defaultDfp: String = "4xtfj"
	private var dfpActive: Bool = false
	
	override func viewDidLoad() {
		//requestMediaSet([String.init(4421), String.init(4460)])
		requestMediaSet([String.init(533)])
		self.tableView.backgroundColor = UIColor.clearColor()
		
		//Button
		let dfpIcon = dfpToggleButton.currentBackgroundImage?.tintPhoto(UIColor.lightGrayColor())
		dfpToggleButton.setImage(dfpIcon, forState: UIControlState.Normal)
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
						thumb: thumbUrl,
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
	
	@IBAction func dfpTapped() {
		enableDfpButton(!dfpActive)
		
		if dfpActive {
			requestAds((dfpTextField.text ?? "").isEmpty ? defaultDfp : dfpTextField.text!)
		}
	}
	
	@IBAction func dfpEditingChanged() {
		enableDfpButton(false)
	}
}

class MediaInfo {
	let title:String
	let thumb:String
	let projectHash:String
	let mediaId:String
	let isAudio:Bool
	var mediaAd:String?
	var description:String?
	
	init(title:String, thumb:String, projectHash:String, mediaId:String, isAudio:Bool = false, description:String? = nil, mediaAd:String? = nil) {
		self.title = title
		self.thumb = thumb
		self.projectHash = projectHash
		self.mediaId = mediaId
		self.isAudio = isAudio
		self.description = description
		self.mediaAd = mediaAd
	}
}
