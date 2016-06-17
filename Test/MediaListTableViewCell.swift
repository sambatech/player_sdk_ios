//
//  MediaListCellViewControllerTableViewCell.swift
//  TesteMobileIOS
//
//  Created by Thiago Miranda on 11/03/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import UIKit

class MediaListTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var mediaThumb: UIImageView?
    @IBOutlet weak var mediaDesc: UITextView!
    @IBOutlet weak var mediaTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		//self.layer.masksToBounds = true
		self.layer.borderWidth = 0.5
		self.layer.borderColor = UIColor( red: 0, green: 0, blue:0, alpha: 1.0 ).CGColor
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
