//
//  ErrorBuilder.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import Foundation
import SwiftyJSON

class ErrorBuilder<U:JSONDecodable>
{
    func buildErrorFromRequest(request : NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> APIError<U> {
        return APIError<U>(request: request, response: response, data: data, error: error)
    }
}

struct APIError<T:JSONDecodable> {
    let request : NSURLRequest?
    let response : NSHTTPURLResponse?
    let data : NSData?
    let error : NSError?
    var errorModel : T?
    
    init(request : NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: NSError?)
    {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
        self.errorModel = data != nil ? T(json: JSON(data: data!)) : nil
    }
    
    init(errorModel: T) {
        self.init(request: nil, response: nil, data: nil, error: nil)
        self.errorModel = errorModel
    }
}

