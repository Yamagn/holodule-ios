//
//  Channel.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/13.
//  Copyright © 2020 ymgn. All rights reserved.
//

import Foundation

public struct Channels: Codable {
    let channels: [Channel]
}
public struct Channel: Codable {
    let channelId: String
    let channelTitle: String
    let publishedAt: String
    let thumbnailUrl: String
}
