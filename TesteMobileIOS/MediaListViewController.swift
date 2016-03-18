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
	
	override func viewDidLoad() {
		requestMediaSet([String.init(4421), String.init(4460)])
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
		var i = 0;

		func request() {
			let pid = pids[i]
			let url = Commons.settings["svapi_endpoint"]! + "medias?access_token=079cc2f1-4733-4c92-a7b5-7e1640698caa&pid=" + pid + "&published=true"
			
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
						projectHash: Commons.settings["pid_" + pid]!,
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
