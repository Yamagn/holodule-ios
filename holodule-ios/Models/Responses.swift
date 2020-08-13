//
//  File.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/13.
//  Copyright © 2020 ymgn. All rights reserved.
//

import Foundation

public struct ChannelList: Codable {
    let items: [ChannelItem]
}
public struct ChannelItem: Codable {
    let snippet: Snippet
}
public struct Snippet: Codable {
    let title: String
    let thumbnails: Thumbnail
}
public struct Thumbnail: Codable {
    let `default`: ThumbnailInfo
    let medium: ThumbnailInfo
    let high: ThumbnailInfo
}
public struct ThumbnailInfo: Codable {
    let url: String
    let width: Double
    let height: Double
}
