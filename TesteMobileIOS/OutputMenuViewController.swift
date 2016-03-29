//
//  OutputMenuViewController.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/23/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import UIKit

class OutputMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate {
	
	private let cellIdentifier: String = "outputCell"
	private let player: SambaPlayer
	private let outputs: [SambaMedia.Output]
	
	init(_ player: SambaPlayer) {
		self.player = player
		self.outputs = player.media.outputs!
		
		super.init(nibName: nil, bundle: nil)
		
		transitioningDelegate = self
		modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
		
		createContent()
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	func close() {
		self.dismissViewControllerAnimated(false, completion: { self.player.play() })
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
		print(outputs[indexPath.row])
		close()
	}
	
	private func createContent() {
		let margin = CGFloat(16)
		var contentSize = CGSizeMake(view.frame.width - 60, 0)
		
		let tableView = UITableView(frame: CGRectMake(0, 0, contentSize.width - margin, contentSize.height), style: UITableViewStyle.Plain)
		tableView.dataSource = self
		tableView.delegate = self
		tableView.layoutIfNeeded()
		var tableFrame = tableView.frame
		tableFrame.size.height = tableView.contentSize.height
		tableView.frame = tableFrame
		tableView.center = view.center

		let closeButton = UIButton(type: UIButtonType.System)
		closeButton.setTitle("Cancelar", forState: UIControlState.Normal)
		closeButton.sizeToFit()
		var btFrame = closeButton.frame
		btFrame.origin = CGPointMake(tableView.frame.origin.x + tableView.frame.width - btFrame.width,
			tableView.frame.origin.y + tableView.frame.height + margin/2)
		closeButton.frame = btFrame
		
		closeButton.addCallback({ self.close() }, forControlEvents: .TouchUpInside)
		
		/*let label = UIButton()
		label.setTitle("Qualidade", forState: UIControlState.Normal)
		label.sizeToFit()
		var labelFrame = closeButton.frame
		labelFrame.origin = CGPointMake(tableView.frame.origin.x, tableView.frame.origin.y)
		label.frame = labelFrame*/
		
		contentSize.height = tableView.contentSize.height + margin + closeButton.frame.height*2
		
		let bgView = UIView(frame: CGRect(origin: view.center, size: contentSize))
		bgView.center = view.center
		bgView.backgroundColor = UIColor.whiteColor()
		bgView.layer.cornerRadius = 5
		
		view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
		
		view.addSubview(bgView)
		//view.addSubview(label)
		view.addSubview(tableView)
		view.addSubview(closeButton)
	}
}
