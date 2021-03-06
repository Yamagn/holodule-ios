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
        return URL(string: host + "/api")!
    }
}

public struct GetChannelList: YouTubeRequest {
    public var dataParser: DataParser {
        return DecodableDataParser()
    }
    
    public typealias Response = Channels
    public var method: HTTPMethod {
        return .get
    }
    public var path: String {
        return "channels"
    }
    
    public func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        guard let data = object as? Data else {
            throw ResponseError.unexpectedObject(object)
        }
        return try JSONDecoder().decode(Channels.self, from: data)
    }
}

public struct GetVideos: YouTubeRequest {
    public var dataParser: DataParser {
        return DecodableDataParser()
    }
    
    public typealias Response = Videos
    public var method: HTTPMethod {
        return .get
    }
    public var path: String {
        return "videos"
    }
    
    public var parameters: Any? {
        return ["from": fromDate]
    }
    
    var fromDate: String
    
    public func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        guard let data = object as? Data else {
            throw ResponseError.unexpectedObject(object)
        }
        return try JSONDecoder().decode(Videos.self, from: data)
    }
}
