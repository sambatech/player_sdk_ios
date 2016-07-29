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
	@IBOutlet var heightConstraint: NSLayoutConstraint!
	
	private let _cellIdentifier: String = "outputCell"
	private let _player: SambaPlayer
	private let _outputs: [SambaMedia.Output]
	private let _selectedIndex: Int
	
	init(_ player: SambaPlayer, _ selectedIndex: Int = -1) {
		_player = player
		_outputs = player.media.outputs!
		_selectedIndex = selectedIndex
		
		super.init(nibName: nil, bundle: nil)
		
		transitioningDelegate = self
		modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
		
		if let nib = NSBundle(forClass: self.dynamicType).loadNibNamed("OutputMenu", owner: self, options: nil).first as? UIView {
			view = nib
		}
		else {
			print("\(self.dynamicType) error: Couldn't load output menu.")
		}
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLayoutSubviews() {
		var frame = tableView.frame
		frame.size.height = tableView.contentSize.height
		heightConstraint.constant = tableView.contentSize.height
		tableView.frame = frame
		tableView.layoutIfNeeded()
	}
	
	// MARK: UITableViewDataSource implementation
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return _outputs.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(_cellIdentifier) ??
			UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: _cellIdentifier)

		cell.textLabel?.text = _outputs[indexPath.row].label
		
		if indexPath.row == _selectedIndex {
			//cell.contentView.backgroundColor = UIColor(_player.media.theme)
			cell.textLabel?.shadowColor = UIColor.blackColor()
		}
		
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		_player.switchOutput(indexPath.row)
		close()
	}
	
	func close() {
		_player.hideMenu(self)
	}
	
	@IBAction func closeHandler(sender: AnyObject) {
		close()
	}
}
