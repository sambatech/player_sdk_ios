//
//  OuptutMenuViewController.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import UIKit

class OutputMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate {
	
	@IBOutlet var tableView: UITableView!
	
	private let cellIdentifier: String = "outputCell"
	private let player: SambaPlayer
	private let outputs: [SambaMedia.Output]
	
	init(_ player: SambaPlayer) {
		self.player = player
		self.outputs = player.media.outputs!
		
		super.init(nibName: nil, bundle: nil)
		
		transitioningDelegate = self
		modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
		
		view = NSBundle.mainBundle().loadNibNamed("OutputMenu", owner: self, options: nil).first as! UIView
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: UITableViewDataSource implementation
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return outputs.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)

		if cell == nil {
			cell = UITableViewCell.init(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
		}
		
		cell?.textLabel?.text = outputs[indexPath.row].label
		
		return cell!
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		player.switchOutput(indexPath.row)
		close()
	}
	
	func close() {
		player.detachVC(self) { self.player.play() }
	}
	
	@IBAction func closeHandler(sender: AnyObject) {
		close()
	}
}
