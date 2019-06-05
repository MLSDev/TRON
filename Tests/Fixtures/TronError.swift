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
import TRONSwiftyJSON

public class CodableError<ErrorModel: Codable> : APIError {
    let errorModel: ErrorModel?
    
    public required init(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) {
        errorModel = data.flatMap { try? JSONDecoder().decode(ErrorModel.self, from: $0) }
        super.init(request: request,
                   response: response,
                   data: data,
                   error: error)
    }
    
    public required init(request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: Error?) {
        errorModel = nil
        super.init(request: request,
                   response: response,
                   fileURL: fileURL,
                   error: error)
    }
}

public class JSONDecodableError<ErrorModel: JSONDecodable> : APIError {
    let errorModel: ErrorModel?
    
    public required init(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) {
        errorModel = data
            .flatMap { try? JSON(data: $0) }
            .flatMap { try? ErrorModel(json: $0) }
        
        super.init(request: request,
                   response: response,
                   data: data,
                   error: error)
    }
    
    public required init(request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: Error?) {
        errorModel = nil
        super.init(request: request,
                   response: response,
                   fileURL: fileURL,
                   error: error)
    }
}
