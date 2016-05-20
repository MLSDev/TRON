//: Playground - noun: a place where people can play

import Cocoa
import ObjectMapper
import TRON
import Foundation

struct ObjectMapperError: ErrorType {}

public protocol ObjectMapperParseable : ResponseParseable {
    init(map: Map)
}

public extension ResponseParseable where Self : ObjectMapperParseable {
    public init(data: NSData) throws {
        guard let dictionary = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject] else {
            throw ObjectMapperError()
        }
        let map = Map(mappingType: .FromJSON, JSONDictionary: dictionary ?? [:])
        self.init(map: map)
    }
}

struct Headers: ObjectMapperParseable {
    
    var host : String!
    
    init(map: Map) {
        host <- map["host"]
    }
}

let tron = TRON(baseURL: "http://httpbin.org")
let request: APIRequest<Headers,Int> = tron.request(path: "headers")
request.perform(success: { headers in
    print(headers.host)
    }, failure: { error in
    print(error)
})
