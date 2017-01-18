//
//  OuptutMenuViewController.swift
//  SambaPlayer SDK
//
//  Created by Leandro Zanol, Priscila Magalhães, Thiago Miranda on 07/07/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import UIKit

class ModalMenu: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate {
	
	@IBOutlet var tableView: UITableView!
	@IBOutlet var heightConstraint: NSLayoutConstraint!
	@IBOutlet var menuTitle: UILabel!
	
	private let _cellIdentifier: String = "menu_cell"
	private let _player: SambaPlayer
	private let _options: [String]
	private let _title: String
	private let _selectedIndex: Int
	private let _onSelect: (Int) -> ()
	
	init(sambaPlayer player: SambaPlayer, options: [String], title: String, onSelect: @escaping (Int) -> (), selectedIndex: Int = -1) {
		_player = player
		_options = options
		_title = title
		_onSelect = onSelect
		_selectedIndex = selectedIndex
		
		super.init(nibName: "ModalMenu", bundle: Bundle(for: type(of: self)))
		
		transitioningDelegate = self
		modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		menuTitle.text = _title
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
		return _options.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: _cellIdentifier) ??
			UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: _cellIdentifier)

		cell.textLabel?.text = _options[(indexPath as NSIndexPath).row]
		
		if (indexPath as NSIndexPath).row == _selectedIndex {
			//cell.contentView.backgroundColor = UIColor(_player.media.theme)
			cell.textLabel?.shadowColor = UIColor.black
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		_onSelect((indexPath as NSIndexPath).row)
		close()
	}
	
	func close() {
		_player.hideMenu(self)
	}
	
	@IBAction func closeHandler(_ sender: AnyObject) {
		close()
	}
}
