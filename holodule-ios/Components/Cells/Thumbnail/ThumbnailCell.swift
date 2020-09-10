//
//  ThumbnailCell.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/13.
//  Copyright © 2020 ymgn. All rights reserved.
//

import UIKit

class ThumbnailCell: UICollectionViewCell {

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var thumbnailView: UIImageView! {
        didSet {
            thumbnailView.layer.cornerRadius = thumbnailView.frame.width / 2.0
        }
    }
    @IBOutlet weak var channelTitleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
