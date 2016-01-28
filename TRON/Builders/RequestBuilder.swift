//
//  RequestBuilder.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import Foundation

public  class URLBuilder : NSURLBuildable {
    public let baseURLString : String
    
    public init(baseURLString: String) {
        self.baseURLString = baseURLString
    }
    
    public func urlForPath(path: String) -> NSURL {
        return NSURL(string: baseURLString)?.URLByAppendingPathComponent(path) ?? NSURL()
    }
}