//
//  HomeViewController.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/12.
//  Copyright © 2020 ymgn. All rights reserved.
//

import UIKit
import APIKit
import Kingfisher
import KRProgressHUD
import Foundation

class MainViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var channels: [Channel]?
    var videos: [Video]?
    let dateFormatter = DateFormatter()
    let isoFormatter = ISO8601DateFormatter()
    var prevDayVideos: [Video] = []
    var currentDayVideos: [Video] = []
    var followingDayVideos: [Video] = []
    var hasChannelSelected: Bool = false
    var selectedChannelRow: Int = 0
    var fromDatetimeIsoString: String {
        return isoFormatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    }
    
    fileprivate let refreshCtrl = UIRefreshControl()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let channelsNib = UINib(nibName: "ChannelsCell", bundle: nil)
        let scheduleNib = UINib(nibName: "ScheduleCell", bundle: nil)
        tableView.register(channelsNib, forCellReuseIdentifier: "ChannelsCell")
        tableView.register(scheduleNib, forCellReuseIdentifier: "ScheduleCell")
        tableView.indexPathsForSelectedRows?.forEach { [weak self] in
            self?.tableView.deselectRow(at: $0, animated: true)
        }
        tableView.refreshControl = refreshCtrl
        refreshCtrl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
    }
    @objc
    func refresh(sender: UIRefreshControl) {
        reloadVideos()
        sender.endRefreshing()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadVideos()
    }
    func reloadVideos() {
        setEmptyView()
        KRProgressHUD.show()
        Session.send(GetChannelList()) { result in
            switch result {
                case.success(let res):
                    self.channels = res.channels
                    self.channels = self.sortChannels(channels: self.channels ?? [])
                    self.tableView.reloadData()
                case .failure(let err):
                    KRProgressHUD.showError(withMessage: err.localizedDescription)
            }
        }
        Session.send(GetVideos(fromDate: fromDatetimeIsoString)) { result in
            switch result {
                case .success(let res):
                    KRProgressHUD.dismiss()
                    self.dismissEmptyView()
                    self.videos = self.sortVideo(videos: res.videos)
                    self.videos = self.filterVideos(src: self.videos ?? [])
                    self.distributeVideos(videos: self.videos ?? [])
                    self.tableView.reloadData()
                    self.moveToCurrent(videos: self.currentDayVideos)
                case .failure(let err):
                    KRProgressHUD.showError(withMessage: err.localizedDescription)
            }
        }
    }
    func isoStringToDate(src: String) -> Date? {
        isoFormatter.timeZone = TimeZone.current
        return isoFormatter.date(from: src)
    }
    func isoDateToString(src: Date) -> String {
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "ja-JP")
        return dateFormatter.string(from: src)
    }
    func convertScheduledAt(video: Video) -> Date {
        if video.isStream {
            return isoStringToDate(src: video.scheduledStartTime!)!
        }
        return isoStringToDate(src: video.publishedAt)!
    }
    func convertCreatedAtFromChannel(channel: Channel) -> Date {
        return isoStringToDate(src: channel.publishedAt)!
    }
    func sortChannels(channels: [Channel]) -> [Channel] {
        var srcChannels = channels
        srcChannels.sort { prevChannel, nextChannel in
            convertCreatedAtFromChannel(channel: prevChannel) < convertCreatedAtFromChannel(channel: nextChannel)
        }
        return srcChannels
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
            abs(calcDateRemainder(firstDate: convertScheduledAt(video: $0))) <= 1
        }
    }
    func distributeVideos(videos: [Video]) {
        initDistributedVideos()
        for video in videos {
            let remain = calcDateRemainder(firstDate: convertScheduledAt(video: video))
            if remain == -1 {
                self.prevDayVideos.append(video)
            } else if remain == 0 {
                self.currentDayVideos.append(video)
            } else if remain == 1 {
                self.followingDayVideos.append(video)
            }
        }
    }
    func initDistributedVideos() {
        self.prevDayVideos = []
        self.currentDayVideos = []
        self.followingDayVideos = []
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
        return Int(floor(ret))
    }
    func moveToCurrent(videos: [Video]) {
        for (index, video) in videos.enumerated() {
            switch video.liveBroadcastContent {
            case .live:
                let indexPath = IndexPath(row: index, section: 2)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                return
            case .upcoming:
                let indexPath = IndexPath(row: index, section: 2)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                return
            default:
                break
            }
        }
    }
    func setEmptyView() {
        let empty = UIView(frame: view.frame)
        empty.backgroundColor = .secondarySystemBackground
        empty.tag = 2
        view.addSubview(empty)
    }
    func dismissEmptyView() {
        let empty = view.viewWithTag(2)
        empty?.removeFromSuperview()
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let nowDate = Date()
        self.dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "dMM", options: 0, locale: Locale(identifier: "ja-JP"))
        switch section {
        case 0:
            return "チャンネル一覧"
        case 1:
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: nowDate)
            return dateFormatter.string(from: yesterday!)
        case 2:
            return dateFormatter.string(from: nowDate)
        case 3:
            let tommorow = Calendar.current.date(byAdding: .day, value: 1, to: nowDate)
            return dateFormatter.string(from: tommorow!)
        default:
            return ""
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return prevDayVideos.count
        } else if section == 2 {
            return currentDayVideos.count
        } else if section == 3 {
            return followingDayVideos.count
        }
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var srcVideos: [Video] = []
        if indexPath.section == 0 {
            let cell: ChannelsCell = tableView.dequeueReusableCell(withIdentifier: "ChannelsCell") as! ChannelsCell
            return cell
        }
        let cell: ScheduleCell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell") as! ScheduleCell
        if indexPath.section == 1 {
            srcVideos = prevDayVideos
        } else if indexPath.section == 2 {
            srcVideos = currentDayVideos
        } else if indexPath.section == 3 {
            srcVideos = followingDayVideos
        }
        return setupScheduleCell(cell: cell, videos: srcVideos, indexPath: indexPath)
    }
    func setupScheduleCell(cell: ScheduleCell, videos: [Video], indexPath: IndexPath) -> ScheduleCell {
        let schedule = videos[indexPath.row]
        
        let channelOptional = self.channels?.filter { $0.channelId == schedule.channelId }[0]
        guard let channel = channelOptional else { return cell }
        
        let processer = DownsamplingImageProcessor(size: cell.channelThumbnail.bounds.size) |> RoundCornerImageProcessor(cornerRadius: 20)
        let videoThumbnailUrl = URL(string: schedule.thumbnailUrl)
        let channelThumbnailUrl = URL(string: channel.thumbnailUrl)
        
        cell.videoThumbnail.kf.setImage(with: videoThumbnailUrl, placeholder: UIImage(named: "no_image.png"))
        cell.channelName.text = schedule.channelTitle
        cell.channelThumbnail.kf.indicatorType = .activity
        cell.channelThumbnail.kf.setImage(with: channelThumbnailUrl, placeholder: UIImage(named: "no_image.png"), options: [.processor(processer), .scaleFactor(UIScreen.main.scale), .transition(.fade(1)), .cacheOriginalImage])
        
        if schedule.isStream {
            let scheduledAtDate = isoStringToDate(src: schedule.scheduledStartTime!)!
            let scheduledAtStr = isoDateToString(src: scheduledAtDate)
            let sepalatedTime = scheduledAtStr.components(separatedBy: " ")[1].components(separatedBy: ":")
            cell.scheduledAt.text = sepalatedTime[0] + ":" + sepalatedTime[1]
            if schedule.liveBroadcastContent.rawValue == "live" {
            }
        } else {
            let publishedAtDate = isoStringToDate(src: schedule.publishedAt)!
            let publishedAtStr = isoDateToString(src: publishedAtDate)
            let sepalatedTime = publishedAtStr.components(separatedBy: " ")[1].components(separatedBy: ":")
            cell.scheduledAt.text = sepalatedTime[0] + ":" + sepalatedTime[1]
        }
        return cell
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ChannelsCell else { return }
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var selectedVideo: Video?
        switch indexPath.section {
        case 1:
            selectedVideo = prevDayVideos[indexPath.row]
        case 2:
            selectedVideo = currentDayVideos[indexPath.row]
        case 3:
            selectedVideo = followingDayVideos[indexPath.row]
        default:
            selectedVideo = nil
        }
        guard let video = selectedVideo else { return }
        guard let url = URL(string: "https://www.youtube.com/watch?v=\(video.videoId)") else { return }
        UIApplication.shared.open(url)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 120 : 300
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
        cell.channelTitleLabel.text = channels[indexPath.row].channelTitle
        cell.thumbnailView.kf.indicatorType = .activity
        cell.thumbnailView.kf.setImage(with: url, placeholder: UIImage(named: "no_image.png"), options: [.processor(processer), .scaleFactor(UIScreen.main.scale), .transition(.fade(1)), .cacheOriginalImage], completionHandler: {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        })
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 90, height: 120)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let channels = self.channels else { return }
        guard let videos = self.videos else { return }
        if self.hasChannelSelected {
            if self.selectedChannelRow != indexPath.row {
                let selectedChannel = channels[indexPath.row]
                self.selectedChannelRow = indexPath.row
                channelFilter(channel: selectedChannel)
            } else {
                self.hasChannelSelected = false
                self.distributeVideos(videos: videos)
            }
        } else {
            self.hasChannelSelected = true
            self.selectedChannelRow = indexPath.row
            let selectedChannel = channels[indexPath.row]
            channelFilter(channel: selectedChannel)
        }
        
        self.tableView.reloadData()
    }
    func channelFilter(channel: Channel) {
        guard let videos = self.videos else { return }
        self.distributeVideos(videos: videos)
        prevDayVideos = prevDayVideos.filter { $0.channelId == channel.channelId }
        currentDayVideos = currentDayVideos.filter { $0 .channelId == channel.channelId }
        followingDayVideos = followingDayVideos.filter { $0.channelId == channel.channelId }
    }
}
