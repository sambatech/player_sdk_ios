//
//  PlayOverlayViewController.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/21/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import MobilePlayer

class PlayOverlayViewController : MobilePlayerOverlayViewController {
	
	private let sambaPlayer: SambaPlayer
	private var imageView: UIImageView?
	
	init(_ sambaPlayer: SambaPlayer) {
		self.sambaPlayer = sambaPlayer
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if imageView != nil { return }
		
		if let image = UIImage(named: "play") {
			imageView = UIImageView(image: image)
			imageView?.center = view.center
			imageView?.userInteractionEnabled = true
			imageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapHandler:"))
			view.addSubview(imageView!)
		}
	}
	
	func tapHandler(img: AnyObject) {
		if sambaPlayer.isPlaying { return }
		sambaPlayer.play()
	}
}
