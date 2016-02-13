//: Playground - noun: a place where people can play

import ObjectMapper
import TRON

struct ObjectMapperError: ErrorType {}

public protocol ObjectMapperParseable : ResponseParseable {
    init?(map: Map)
}

public extension ResponseParseable where Self.ModelType : ObjectMapperParseable {
    public static func from(json: AnyObject) throws -> ModelType {
        let map = Map(mappingType: .FromJSON, JSONDictionary: json as! [String:AnyObject], toObject: true)
        guard let model = ModelType(map: map) else {
            throw ObjectMapperError()
        }
        return model
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




