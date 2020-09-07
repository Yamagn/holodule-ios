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
import KRProgressHUD

class MainViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var channels: [Channel]?
    var videos: [Video]?
    let dateFormatter = DateFormatter()
    
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
        KRProgressHUD.show()
        Session.send(GetChannelList()) { result in
            switch result {
                case.success(let res):
                    self.channels = res.channels
                    self.tableView.reloadData()
                case .failure(let err):
                    KRProgressHUD.showError(withMessage: err.localizedDescription)
            }
        }
        Session.send(GetVideos()) { result in
            switch result {
                case .success(let res):
                    KRProgressHUD.dismiss()
                    self.videos = self.sortVideo(videos: res.videos)
                    self.videos = self.filterVideos(src: self.videos ?? [])
                    print(self.videos)
                    self.tableView.reloadData()
                case .failure(let err):
                    KRProgressHUD.showError(withMessage: err.localizedDescription)
            }
        }
    }
    func isoStringToDate(src: String) -> Date? {
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        return dateFormatter.date(from: src)
    }
    func isoDateToString(src: Date) -> String {
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: src)
    }
    func convertScheduledAt(video: Video) -> Date {
        if video.isStream {
            return isoStringToDate(src: video.scheduledStartTime!)!
        }
        return isoStringToDate(src: video.publishedAt)!
    }
    func sortVideo(videos: [Video]) -> [Video] {
        var srcVideos = videos
        srcVideos.sort { prevVideo, nextVideo in
            convertScheduledAt(video: prevVideo) < convertScheduledAt(video: nextVideo)
        }
        return srcVideos
    }
    func filterVideos(src: [Video]) -> [Video] {
        return src.filter {
            calcDateRemainder(firstDate: convertScheduledAt(video: $0)) <= 1
        }
    }
    func resetTime(date: Date) -> Date {
        let calender = Calendar(identifier: .gregorian)
        var components = calender.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        return calender.date(from: components)!
    }
    func calcDateRemainder(firstDate: Date, secondDate: Date? = nil) -> Int {
        var retInterval: Double!
        let firstDateReset = resetTime(date: firstDate)
        
        if let second = secondDate {
            let secondDateReset = resetTime(date: second)
            retInterval = firstDateReset.timeIntervalSince(secondDateReset)
        } else {
            let nowDate = Date()
            let nowDateReset = resetTime(date: nowDate)
            retInterval = firstDateReset.timeIntervalSince(nowDateReset)
        }
        let ret = retInterval/86400
        let tmp = abs(Int(floor(ret)))
        print(tmp)
        return tmp
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let schedulesCount = self.videos?.count else {
            return 1
        }
        return schedulesCount + 1 
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell: ChannelsCell = tableView.dequeueReusableCell(withIdentifier: "ChannelsCell") as! ChannelsCell
            print(cell)
            return cell
        default:
            let schedule = self.videos?[indexPath.row - 1]
            let cell: ScheduleCell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell") as! ScheduleCell
            
            let channelOptional = self.channels?.filter { $0.channelId == schedule?.channelId ?? "" }[0]
            guard let channel = channelOptional else { return cell }
            
            let processer = DownsamplingImageProcessor(size: cell.channelThumbnail.bounds.size) |> RoundCornerImageProcessor(cornerRadius: 20)
            let videoThumbnailUrl = URL(string: schedule?.thumbnailUrl ?? "")
            let channelThumbnailUrl = URL(string: channel.thumbnailUrl)
            
            cell.videoThumbnail.kf.setImage(with: videoThumbnailUrl, placeholder: UIImage(named: "no_image.png"))
            cell.channelName.text = schedule?.channelTitle
            cell.channelThumbnail.kf.indicatorType = .activity
            cell.channelThumbnail.kf.setImage(with: channelThumbnailUrl, placeholder: UIImage(named: "no_image.png"), options: [.processor(processer), .scaleFactor(UIScreen.main.scale), .transition(.fade(1)), .cacheOriginalImage])
            
            if schedule?.isStream ?? false {
                let scheduledAtDate = isoStringToDate(src: (schedule?.scheduledStartTime!)!)!
                let scheduledAtStr = isoDateToString(src: scheduledAtDate)
                let sepalatedTime = scheduledAtStr.components(separatedBy: " ")[1].components(separatedBy: ":")
                cell.scheduledAt.text = sepalatedTime[0] + ":" + sepalatedTime[1]
            } else {
                let publishedAtDate = isoStringToDate(src: (schedule?.publishedAt)!)!
                let publishedAtStr = isoDateToString(src: publishedAtDate)
                let sepalatedTime = publishedAtStr.components(separatedBy: " ")[1].components(separatedBy: ":")
                cell.scheduledAt.text = sepalatedTime[0] + ":" + sepalatedTime[1]
            }
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
        return channels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ThumbnailCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as! ThumbnailCell
        guard let channels = self.channels else { return cell }
        let url = URL(string: channels[indexPath.row].thumbnailUrl)
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
