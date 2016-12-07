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
	private let _outputs: [SambaMediaOutput]
	private let _selectedIndex: Int
	
	init(_ player: SambaPlayer, _ selectedIndex: Int = -1) {
		_player = player
		_outputs = player.media.outputs!
		_selectedIndex = selectedIndex
		
		super.init(nibName: nil, bundle: nil)
		
		transitioningDelegate = self
		modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
		
		if let nib = Bundle(for: type(of: self)).loadNibNamed("OutputMenu", owner: self, options: nil)?.first as? UIView {
			view = nib
		}
		else {
			print("\(type(of: self)) error: Couldn't load output menu.")
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
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return _outputs.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: _cellIdentifier) ??
			UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: _cellIdentifier)

		cell.textLabel?.text = _outputs[(indexPath as NSIndexPath).row].label
		
		if (indexPath as NSIndexPath).row == _selectedIndex {
			//cell.contentView.backgroundColor = UIColor(_player.media.theme)
			cell.textLabel?.shadowColor = UIColor.black
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		_player.switchOutput((indexPath as NSIndexPath).row)
		close()
	}
	
	func close() {
		_player.hideMenu(self)
	}
	
	@IBAction func closeHandler(_ sender: AnyObject) {
		close()
	}
}
