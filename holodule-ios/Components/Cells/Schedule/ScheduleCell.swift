//
//  ScheduleCell.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/13.
//  Copyright © 2020 ymgn. All rights reserved.
//

import UIKit

class ScheduleCell: UITableViewCell {
    @IBOutlet weak var videoThumbnail: UIImageView!
    @IBOutlet weak var channelThumbnail: UIImageView! {
        didSet {
            channelThumbnail.layer.cornerRadius = channelThumbnail.frame.width / 2.0
        }
    }
    @IBOutlet weak var channelName: UILabel! {
        didSet {
            channelName.adjustsFontSizeToFitWidth = true
            channelName.minimumScaleFactor = 0.2
            channelName.numberOfLines = 1
        }
    }
    @IBOutlet weak var scheduledAt: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
