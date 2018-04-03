//
//  JSONDecodableTestCase.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import XCTest
@testable import TRON
import Nimble
import SwiftyJSON
import Alamofire

private struct Headers : JSONDecodable {
    
    let host : String
    
    init(json: JSON) {
        let headers = json["headers"].dictionaryValue
        host = headers["Host"]?.stringValue ?? ""
    }
}

class Ancestor: JSONDecodable {
    required init(json: JSON) {
        
    }
}

class Sibling: Ancestor {
    let foo: String = "4"
    
    required init(json: JSON) {
        super.init(json: json)
    }
}
struct ThrowError : Error {}

class Throwable : JSONDecodable {
    required init(json: JSON) throws {
        throw ThrowError()
    }
}

class JSONDecodableTestCase: XCTestCase {
    let tron = TRON(baseURL: "https://github.com")
    
    func testDecodableArray() throws {
        let request: APIRequest<[Int],TronError> = tron.swiftyJSON.request("foo")
        let json = [1,2,3,4]
        let parsedResponse = try request.responseParser(nil, nil, JSONSerialization.data(withJSONObject:json, options: []), nil).unwrap()
        
        expect(parsedResponse) == [1,2,3,4]
    }
 
    func testVariousJSONDecodableTypes()
    {
        let json = JSON([])
        expect(Float.init(json: json)) == 0
        expect(Double.init(json: json)) == 0
        expect(Bool.init(json: json)) == false
        expect(try! JSON.init(json: json)) == json
    }

    func testJSONDecodableParsing() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<Headers,Int> = tron.swiftyJSON.request("headers")
        let expectation = self.expectation(description: "Parsing headers response")
        request.perform(withSuccess:  { headers in
            if headers.host == "httpbin.org" {
                expectation.fulfill()
            }
        })
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testJSONDecodableWorksWithSiblings() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<Sibling,Int> = tron.swiftyJSON.request("headers")
        let expectation = self.expectation(description: "Parsing headers response")
        request.perform(withSuccess:  { sibling in
            if sibling.foo == "4" {
                expectation.fulfill()
            }
        })
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
//    func testJSONDecodableParsingEmptyResponse() {
//        let tron = TRON(baseURL: "http://httpbin.org")
//        let request: APIRequest<Headers,Int> = tron.request("headers")
//        let responseSerializer = request.dataResponseSerializer(with: [])
//        let result = responseSerializer.serializeResponse(nil,nil, nil,nil)
//        
//        if case Alamofire.Result.success(_) = result {
//            
//        } else {
//            XCTFail()
//        }
//    }
}
