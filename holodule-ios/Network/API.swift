//
//  API.swift
//  holodule-ios
//
//  Created by ymgn on 2020/08/12.
//  Copyright © 2020 ymgn. All rights reserved.
//

import Foundation
import APIKit

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
        return URL(string: "https://www.googleapis.com/youtube/v3/")!
    }
}

public struct GetChannelList: YouTubeRequest {
    public var dataParser: DataParser {
        return DecodableDataParser()
    }
    
    public typealias Response = ChannleList
    public var method: HTTPMethod {
        return .get
    }
    public var path: String {
        return "channels"
    }
    public var parameters: Any? {
        return ["forUsername": username, "key": key]
    }
    
    let username: String
    let key: String
    
    public func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        print(object)
        guard let data = object as? Data else {
            throw ResponseError.unexpectedObject(object)
        }
        return try JSONDecoder().decode(ChannleList.self, from: data)
    }
}
