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
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
