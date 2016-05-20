//: Playground - noun: a place where people can play

import Cocoa

import Unbox
import TRON
import Foundation

struct UnboxMapperError: ErrorType {}

public extension ResponseParseable where Self: Unboxable {
    init(data: NSData) throws {
        // There seems to be no way to directly call initializers with unbox, so we forbid such initializer
        throw UnboxMapperError()
    }
}

public class UnboxResponseBuilder<T:ResponseParseable where T: Unboxable> : ResponseBuilder<T>
{
    public override init() {}
    
    public override func buildResponseFromData(data: NSData) throws -> T {
        return try Unbox(data)
    }
}

struct Headers: Unboxable, ResponseParseable {
    
    var host : String
    
    init(unboxer: Unboxer) {
        host = unboxer.unbox("host")
    }
}

let tron = TRON(baseURL: "http://httpbin.org")
let request: APIRequest<Headers,Int> = tron.request(path: "headers")
request.responseBuilder = UnboxResponseBuilder()
request.perform(success: { headers in
    print(headers.host)
    }, failure: { error in
        print(error)
})