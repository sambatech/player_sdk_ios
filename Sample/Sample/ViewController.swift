//
//  ViewController.swift
//  Sample
//
//  Created by Leandro Zanol on 5/18/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import UIKit

class ViewController: UIViewController/*, GMFVideoPlayerDelegate*/ {

	@IBOutlet var videoContainer: UIView!
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		let gmf = GMFPlayerViewController()
		
		gmf.loadStreamWithURL(NSURL(string: "http://gbbrpvbps-sambavideos.akamaized.net/account/37/2/2015-11-05/video/cb7a5d7441741d8bcb29abc6521d9a85/marina_360p.mp4"))

		addChildViewController(gmf)
		gmf.view.frame = videoContainer.frame
		videoContainer.addSubview(gmf.view)
		
		gmf.play()

		//presentViewController(gmf, animated: true, completion: nil)
	}
	
	func videoPlayer(videoPlayer:GMFVideoPlayer, stateDidChangeFrom fromState:GMFPlayerState, to toState:GMFPlayerState) {
		
	}
	
	// Called whenever media time changes during playback.
	/*- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
	currentMediaTimeDidChangeToTime:(NSTimeInterval)time;
	
	// Called when the media duration changes during playback
	- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
	currentTotalTimeDidChangeToTime:(NSTimeInterval)time;
	
	@optional
	// Called whenever buffered media time changes during playback or while loading or paused.
	- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
	bufferedMediaTimeDidChangeToTime:(NSTimeInterval)time;*/
}

