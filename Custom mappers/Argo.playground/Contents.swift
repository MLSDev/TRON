//: Playground - noun: a place where people can play

import UIKit
import Argo
import TRON
import Curry

public struct ArgoDecodableError : ErrorType {}

public extension Decodable where Self: ResponseParseable {

    public static func from(json: AnyObject) throws -> ModelType {
        guard let model = decode(JSON.parse(json)) as? ModelType else {
            throw ArgoDecodableError()
        }
        return model
    }
}
struct ArgoHeaders : Decodable, ResponseParseable {
    
    let host : String
    
    static func decode(j: JSON) -> Decoded<ArgoHeaders> {
        return curry(ArgoHeaders.init)
            <^> j <| "host"
    }
}

let tron = TRON(baseURL: "http://httpbin.org")
let request: APIRequest<ArgoHeaders,Int> = tron.request(path: "headers")
request.performWithSuccess({ headers in
    print(headers.host)
})
