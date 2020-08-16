//
//  Video.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/13.
//  Copyright © 2020 ymgn. All rights reserved.
//

import Foundation

public struct Videos: Codable {
    let videos: [Video]
}
public struct Video: Codable {
    let videoId: String
    let publishedAt: String
    let channelId: String
    let title: String
    let thumbnailUrl: String
    let channelTitle: String
    let liveBroadcastContent: LiveStatus
    let scheduledStartTime: String?
    var isStream: Bool {
        get {
            return self.scheduledStartTime != nil
        }
    }
}

public enum LiveStatus: String, Codable {
    case upcoming = "upcoming"
    case live = "live"
    case none = "none"
}
