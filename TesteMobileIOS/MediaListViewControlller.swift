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
	
	private var mediaList:[SambaMedia] = []
	
	override func viewDidLoad() {
		Alamofire.request(.GET, "http://api.sambavideos.sambatech.com/v1/medias?access_token=079cc2f1-4733-4c92-a7b5-7e1640698caa&pid=4460&published=true")
			.responseJSON { response in
				if let json = response.result.value as? [AnyObject] {
					var mediaList = [SambaMedia]()
					
					for jsonNode in json {
						if (jsonNode["qualifier"] as? String ?? "").lowercaseString != "video" {
							continue
						}
						
						var outputs = [Output]()
						
						for jsonOutput in jsonNode["files"] as! [AnyObject] {
							outputs.append(Output(
								url: jsonOutput["url"] as? String ?? "",
								label: jsonOutput["outputName"] as? String ?? ""))
						}
						
						mediaList.append(SambaMedia(
							title: jsonNode["title"] as? String ?? "",
							outputs: outputs,
							thumb: jsonNode["thumbs"]!![0]["url"] as? String ?? ""))
					}
					
					self.tableView.reloadData()
				}
				else  {
					print("Invalid JSON format!")
				}
		}
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
}
