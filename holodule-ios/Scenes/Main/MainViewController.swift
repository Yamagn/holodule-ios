//
//  HomeViewController.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/12.
//  Copyright © 2020 ymgn. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import APIKit
import Kingfisher

class MainViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var channels: ChannelList?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let channelsNib = UINib(nibName: "ChannelsCell", bundle: nil)
        let scheduleNib = UINib(nibName: "ScheduleCell", bundle: nil)
        tableView.register(channelsNib, forCellReuseIdentifier: "ChannelsCell")
        tableView.register(scheduleNib, forCellReuseIdentifier: "ScheduleCell")
        tableView.indexPathsForSelectedRows?.forEach { [weak self] in
            self?.tableView.deselectRow(at: $0, animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        Session.send(GetChannelList()) { result in
            switch result {
                case.success(let res):
                    self.channels = res
                    self.tableView.reloadData()
                case .failure(let res):
                    print("fetch failure")
            }
        }
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell: ChannelsCell = tableView.dequeueReusableCell(withIdentifier: "ChannelsCell") as! ChannelsCell
            print(cell)
            return cell
        default:
            let cell: ScheduleCell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell") as! ScheduleCell
            return cell
        }
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ChannelsCell else { return }
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
    }
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let channels = self.channels else {
            return 0
        }
        return channels.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ThumbnailCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as! ThumbnailCell
        guard let channels = self.channels else { return cell }
        let url = URL(string: channels.items[indexPath.row].snippet.thumbnails.default.url)
        let processer = DownsamplingImageProcessor(size: cell.thumbnailView.bounds.size) |> RoundCornerImageProcessor(cornerRadius: 20)
        cell.thumbnailView.kf.indicatorType = .activity
        cell.thumbnailView.kf.setImage(with: url, placeholder: UIImage(named: "no_image.png"), options: [.processor(processer), .scaleFactor(UIScreen.main.scale), .transition(.fade(1)), .cacheOriginalImage]){
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = 44
        let height = width
        return CGSize(width: width, height: height)
    }
}
