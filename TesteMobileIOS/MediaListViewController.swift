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
	
	private var mediaList:[MediaInfo] = [MediaInfo]()
	private var currentMediaInfo:MediaInfo?
	
	override func viewDidLoad() {
		requestMediaSet([String.init(4421), String.init(4460)])
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		(segue.destinationViewController as! PlayerViewController).mediaInfo = self.currentMediaInfo
	}
	
	override func tableView(tableView: UITableView?, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView!.dequeueReusableCellWithIdentifier("MediaListCellProto") ??
			UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "MediaListCellProto")
		
		let media = mediaList[indexPath.row]
		
		cell.textLabel!.text = media.title
		
		return cell
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return mediaList.count
	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
		currentMediaInfo = mediaList[indexPath.row]
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
	}
	
	private func requestMediaSet(pids:[String]) {
		var i = 0;

		func request() {
			let pid = pids[i]
			let url = Commons.dict["svapi_endpoint"]! + "medias?access_token=079cc2f1-4733-4c92-a7b5-7e1640698caa&pid=" + pid + "&published=true"
			
			print(url)
			
			Alamofire.request(.GET, url).responseJSON { response in
				guard let json = response.result.value as? [AnyObject] else {
					print("Error: Invalid JSON format!")
					return
				}
				
				for jsonNode in json {
					// skip non video media
					if (jsonNode["qualifier"] as? String ?? "").lowercaseString != "video" {
						continue
					}
					
					self.mediaList.append(MediaInfo(
						title: jsonNode["title"] as? String ?? "",
						thumb: jsonNode["thumbs"]!![0]["url"] as? String ?? "",
						projectHash: Commons.dict["pid_" + pid]!,
						mediaId: jsonNode["id"] as? String ?? ""
					))
				}
				
				if ++i == pids.count {
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
}

class MediaInfo : CustomStringConvertible {
	let title:String
	let thumb:String
	let projectHash:String
	let mediaId:String
	
	init(title:String, thumb:String, projectHash:String, mediaId:String) {
		self.title = title
		self.thumb = thumb
		self.projectHash = projectHash
		self.mediaId = mediaId
	}

	var description:String { return title; }
}
