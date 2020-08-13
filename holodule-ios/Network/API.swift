//
//  API.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/12.
//  Copyright © 2020 ymgn. All rights reserved.
//

import Foundation
import APIKit

fileprivate let key = APIKEY
fileprivate let ids: String = IDS.reduce("") { $0 + $1 + "," }

final class DecodableDataParser: DataParser {
    var contentType: String? {
        return "application/json"
    }
    func parse(data: Data) throws -> Any {
        return data
    }
}

protocol YouTubeRequest: Request {}

extension YouTubeRequest {
    public var baseURL: URL {
        return URL(string: "https://www.googleapis.com/youtube/v3")!
    }
}

public struct GetChannelList: YouTubeRequest {
    public var dataParser: DataParser {
        return DecodableDataParser()
    }
    
    public typealias Response = ChannelList
    public var method: HTTPMethod {
        return .get
    }
    public var path: String {
        return "channels"
    }
    public var parameters: Any? {
        return ["part": "snippet", "id": ids, "key": key]
    }
    
    public func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        guard let data = object as? Data else {
            throw ResponseError.unexpectedObject(object)
        }
        return try JSONDecoder().decode(ChannelList.self, from: data)
    }
}
