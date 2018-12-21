//
//  Serialization.swift
//  TRON
//
//  Created by Denys Telezhkin on 12/21/18.
//  Copyright © 2018 Denys Telezhkin. All rights reserved.
//

import Foundation
import Alamofire

public struct TRONDataResponseSerializer<Model> : DataResponseSerializerProtocol {

    public let closure: ((URLRequest?, HTTPURLResponse?, Data?, Error?) throws -> Model)

    public init(closure: @escaping (URLRequest?, _ response: HTTPURLResponse?, _ data: Data?, _ error: Error?) throws -> Model) {
        self.closure = closure
    }

    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Model {
        return try closure(request, response, data, error)
    }
}

public struct TRONDownloadResponseSerializer<Model> : DownloadResponseSerializerProtocol {

    public let closure: ((URLRequest?, HTTPURLResponse?, URL?, Error?) throws -> Model)

    public init(closure: @escaping (URLRequest?, HTTPURLResponse?, URL?, Error?) throws -> Model) {
        self.closure = closure
    }

    public func serializeDownload(request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: Error?) throws -> Model {
        return try closure(request, response, fileURL, error)
    }
}
