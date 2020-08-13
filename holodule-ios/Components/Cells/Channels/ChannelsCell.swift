//
//  ChannelsCell.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/13.
//  Copyright © 2020 ymgn. All rights reserved.
//

import UIKit

class ChannelsCell: UITableViewCell {
    @IBOutlet weak var thumbnailCollectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let nib = UINib(nibName: "ThumbnailCell", bundle: nil)
        thumbnailCollectionView.register(nib, forCellWithReuseIdentifier: "ThumbnailCell")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCollectionViewDataSourceDelegate<D: UICollectionViewDelegate & UICollectionViewDataSource>(dataSourceDelegate: D, forRow row: Int) {
        thumbnailCollectionView.delegate = dataSourceDelegate
        thumbnailCollectionView.dataSource = dataSourceDelegate
        thumbnailCollectionView.reloadData()
    }
}
