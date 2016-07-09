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
struct ThrowError : ErrorProtocol {}

class Throwable : JSONDecodable {
    required init(json: JSON) throws {
        throw ThrowError()
    }
}

class JSONDecodableTestCase: XCTestCase {
    let tron = TRON(baseURL: "https://github.com")
    
    // TODO - Implement parsing for collection types
    
    func testDecodableArray() {
        let request: APIRequest<[Int],TronError> = tron.request(path: "foo")
        let json = [1,2,3,4]
        let parsedResponse = try! request.responseBuilder.buildResponseFromData(JSONSerialization.data(withJSONObject:json, options: []))
        
        expect(parsedResponse) == [1,2,3,4]
    }
    
    func testDecodableSupportsThrowingErrors() {
        let request: APIRequest<Throwable,TronError> = tron.request(path: "foo")
        let data = try! JSONSerialization.data(withJSONObject: [1], options: [])
        let parsedResponse = try? request.responseBuilder.buildResponseFromData(data)
        
        expect(parsedResponse).to(beNil())
    }

    // TODO - implement this stuff when Swift 3.0 comes out
    
//    func testNonDecodableItemsAreThrownOut() {
//        let request: APIRequest<[Int],TronError> = tron.request(path: "foo")
//        let json = [1,2,3,4, "foo"]
//        let parsedResponse = try! request.responseBuilder.buildResponseFromData(NSJSONSerialization.dataWithJSONObject(json, options: []))
//        
//        expect(parsedResponse) == [1,2,3,4]
//    }
 
    func testVariousJSONDecodableTypes()
    {
        let json = JSON(data: Data())
        expect(Float.init(json: json)) == 0
        expect(Double.init(json: json)) == 0
        expect(Bool.init(json: json)) == false
        expect(JSON.init(json: json)) == json
    }

    func testJSONDecodableParsing() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<Headers,Int> = tron.request(path: "headers")
        let expectation = self.expectation(withDescription: "Parsing headers response")
        request.perform(success: { headers in
            if headers.host == "httpbin.org" {
                expectation.fulfill()
            }
        })
        
        waitForExpectations(withTimeout: 3, handler: nil)
    }
    
    func testJSONDecodableWorksWithSiblings() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<Sibling,Int> = tron.request(path: "headers")
        let expectation = self.expectation(withDescription: "Parsing headers response")
        request.perform(success: { sibling in
            if sibling.foo == "4" {
                expectation.fulfill()
            }
        })
        
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testJSONDecodableParsingEmptyResponse() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<Headers,Int> = tron.request(path: "headers")
        let responseSerializer = request.responseSerializer(notifyingPlugins: [])
        let result = responseSerializer.serializeResponse(nil,nil, nil,nil)
        
        if case Alamofire.Result.success(_) = result {
            
        } else {
            XCTFail()
        }
    }
}
