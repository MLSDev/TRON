//: Playground - noun: a place where people can play

import UIKit
import Argo
import TRON

struct ObjectMapperError: ErrorType {}

public protocol ObjectMapperParseable : ResponseParseable {
    init(json: JSON)
}

public extension ResponseParseable where Self.ModelType : ObjectMapperParseable {
    public static func from(json: AnyObject) throws -> ResponseBox<ModelType> {
        let json = JSON.parse(json)
        let decoded = Self.ModelType.decode(json)
        guard let decodedValue = decoded.value as? ModelType else {
            throw ArgoDecodableError()
        }
        return ResponseBox(response: decodedValue)
        return ResponseBox(response: model)
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
request.performWithSuccess({ headers in
    print(headers.host)
})