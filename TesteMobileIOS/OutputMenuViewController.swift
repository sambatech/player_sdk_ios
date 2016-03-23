//
//  OutputMenuViewController.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/23/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import UIKit

class OutputMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	private let cellIdentifier: String = "outputCell"
	private let outputs: [SambaMedia.Output]
	
	init(_ outputs: [SambaMedia.Output]) {
		self.outputs = outputs
		
		super.init(nibName: nil, bundle: nil)

		var frame = CGRect(x: 0, y: 0,
			width: view.frame.width - 60, height: view.frame.height)
		
		let tableView = UITableView(frame: frame, style: UITableViewStyle.Plain)
		
		tableView.dataSource = self
		tableView.delegate = self
		tableView.layoutIfNeeded()
		frame.size.height = tableView.contentSize.height
		frame.origin.x = view.center.x - frame.width/2
		frame.origin.y = view.center.y - frame.height/2
		tableView.frame = frame
		
		view.addSubview(tableView)
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
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
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
}
