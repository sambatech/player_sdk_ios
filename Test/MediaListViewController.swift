//
//  MediaListViewControlller.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/3/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import AVKit
import Alamofire

class MediaListViewController : UITableViewController {
	
	@IBOutlet weak var dfpToggle: UIButton!
	private var mediaList: [MediaInfo] = [MediaInfo]()
	private var mediaListBackup: [MediaInfo] = [MediaInfo]()
	private var currentDfp: String = "4xtfj"
	private var dfpActive: Bool = false
	
	
	override func viewDidLoad() {
		//requestMediaSet([String.init(4421), String.init(4460)])
		requestMediaSet([String.init(533)])
		self.tableView.backgroundColor = UIColor.clearColor()
		
		//Button
		let dfpIcon = dfpToggle.currentBackgroundImage?.tintPhoto(UIColor.lightGrayColor())
		dfpToggle.setImage(dfpIcon, forState: UIControlState.Normal)
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
		
		if indexPath.row % 2 == 0 {
			cell.contentView.backgroundColor = UIColor.darkGrayColor()
		}else {
			cell.contentView.backgroundColor = UIColor.lightGrayColor()
		}

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
			
			print(url)
			
			Helpers.requestURL(url) { responseText in
				guard let responseText = responseText,
					jsonData = responseText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) else { return }
				
				var jsonOpt: [AnyObject]?
				
				do {
					jsonOpt = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as? [AnyObject]
				}
				catch {
					print("\(self.dynamicType) Erro ao dar parse em JSON string.")
				}
				
				guard let json = jsonOpt else {
					print("\(self.dynamicType) Object JSON inválido.")
					return
				}
				dispatch_async(dispatch_get_main_queue()) {
					for jsonNode in json {
						// skip non video media
						if (jsonNode["qualifier"] as? String ?? "").lowercaseString != "video" {
							continue
						}
						
						let m = MediaInfo(
							title: jsonNode["title"] as? String ?? "",
							thumb: jsonNode["thumbs"]!![0]["url"] as? String ?? "",
							projectHash: Helpers.settings["pid_" + pid]!,
							mediaId: jsonNode["id"] as? String ?? "",
							description: nil,
							mediaAd: nil
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
		}
		
		if i < pids.count {
			request()
		}
	}
	
	private func requestAds(hash: String) {
		let url = "\(Helpers.settings["myjson_endpoint"]!)\(hash)"
		Helpers.requestURL(url) { responseText in
			guard let responseText = responseText,
				jsonData = NSData(contentsOfFile: responseText) else { return }
			
			var jsonOpt: [AnyObject]?
			
			do {
				jsonOpt = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as? [AnyObject]
			}
			catch {
				print("\(self.dynamicType) Erro ao dar parse em JSON string.")
			}
			
			guard let json = jsonOpt else {
				print("\(self.dynamicType) Object JSON inválido.")
				return
			}
			
			var dfpIndex:Int = 0
			self.mediaListBackup = self.mediaList
			var dfpMediaList = [MediaInfo]()
			
			for media in self.mediaList {
				if dfpIndex < json.count {
					let m = MediaInfo(
						title: media.title,
						thumb: media.thumb,
						projectHash: media.projectHash,
						mediaId: media.mediaId,
						description: json[dfpIndex]["name"] as? String,
						mediaAd: json[dfpIndex]["url"] as? String
					)
					
					dfpMediaList.append(m)
					
					dfpIndex += 1
				}else {
					dfpIndex = 0
				}
			}
			self.mediaList = dfpMediaList
			self.tableView.reloadData()
			
		}
	}
	
	@IBAction func toggleDfp(sender: UIButton, forEvent event: UIEvent) {
		if !dfpActive {
			let dfpIcon = sender.currentBackgroundImage?.tintPhoto(UIColor.clearColor())
			sender.setImage(dfpIcon, forState: UIControlState.Normal)
			requestAds(currentDfp)
		}else {
			self.mediaList = self.mediaListBackup
			self.tableView.reloadData()
			let dfpIcon = dfpToggle.currentBackgroundImage?.tintPhoto(UIColor.lightGrayColor())
			dfpToggle.setImage(dfpIcon, forState: UIControlState.Normal)
		}
		dfpActive = !dfpActive
	}
}

class MediaInfo {
	let title:String
	let thumb:String
	let projectHash:String
	let mediaId:String
	let mediaAd:String?
	let description:String?
	
	init(title:String, thumb:String, projectHash:String, mediaId:String, description:String?, mediaAd:String?) {
		self.title = title
		self.thumb = thumb
		self.projectHash = projectHash
		self.mediaId = mediaId
		self.description = description ?? title
		self.mediaAd = mediaAd
	}
	
}
