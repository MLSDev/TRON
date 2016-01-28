//
//  ErrorBuilder.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import Foundation
import SwiftyJSON

public class ErrorBuilder<U:JSONDecodable>
{
    func buildErrorFromRequest(request : NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> APIError<U> {
        return APIError<U>(request: request, response: response, data: data, error: error)
    }
}

public struct APIError<T:JSONDecodable> {
    public let request : NSURLRequest?
    public let response : NSHTTPURLResponse?
    public let data : NSData?
    public let error : NSError?
    public var errorModel : T?
    
    public init(request : NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: NSError?)
    {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
        self.errorModel = data != nil ? T(json: JSON(data: data!)) : nil
    }
    
    public init(errorModel: T) {
        self.init(request: nil, response: nil, data: nil, error: nil)
        self.errorModel = errorModel
    }
}

