//
//  APIError.swift
//  TRON
//
//  Created by Denys Telezhkin on 28.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import TRON
import SwiftyJSON

public class CodableError<Model, ErrorModel: Codable> : APIError<Model> {
    let errorModel: ErrorModel?
    
    public required init?(serializedObject: Model?, request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) {
        if let data = data {
            errorModel = try? JSONDecoder().decode(ErrorModel.self, from: data)
        } else {
            errorModel = nil
        }
        super.init(serializedObject: serializedObject,
                   request: request,
                   response: response,
                   data: data,
                   error: error)
    }
    
    public required init?(serializedObject: Model?, request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: Error?) {
        errorModel = nil
        super.init(serializedObject: serializedObject,
                   request: request,
                   response: response,
                   fileURL: fileURL,
                   error: error)
    }
}

public class JSONDecodableError<Model, ErrorModel: JSONDecodable> : APIError<Model> {
    let errorModel: ErrorModel?
    
    public required init?(serializedObject: Model?, request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) {
        if let data = data, let json = try? JSON(data: data) {
            errorModel = try? ErrorModel(json: json)
        } else {
            errorModel = nil
        }
        super.init(serializedObject: serializedObject,
                   request: request,
                   response: response,
                   data: data,
                   error: error)
    }
    
    public required init?(serializedObject: Model?, request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: Error?) {
        errorModel = nil
        super.init(serializedObject: serializedObject,
                   request: request,
                   response: response,
                   fileURL: fileURL,
                   error: error)
    }
}
