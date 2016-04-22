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

private struct Headers : JSONDecodable, ResponseParseable {
    
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
    typealias ModelType = Sibling
    
    let foo: String = "4"
    
    required init(json: JSON) {
        super.init(json: json)
    }
}

class JSONDecodableTestCase: XCTestCase {
    let tron = TRON(baseURL: "https://github.com")
    
    // TODO - Implement parsing for collection types
    
//    func testDecodableArray() {
//        let request: APIRequest<[Int],TronError> = tron.request(path: "foo")
//        let json = [1,2,3,4]
//        let parsedResponse = try! request.responseBuilder.buildResponseFromJSON(json)
//        
//        expect(parsedResponse) == [1,2,3,4]
//    }

    // TODO - implement this stuff when Swift 3.0 comes out
    
//    func testNonDecodableItemsAreThrownOut() {
//        let request: APIRequest<[Int],TronError> = tron.request(path: "foo")
//        let json = JSON([1,2,3,4, "foo"])
//        let parsedResponse = request.responseBuilder.buildResponseFromJSON(json)
//        
//        expect(parsedResponse) == [1,2,3,4]
//    }
 
    func testVariousJSONDecodableTypes()
    {
        let json = JSON(data: NSData())
        expect(Float.init(json: json)) == 0
        expect(Double.init(json: json)) == 0
        expect(Bool.init(json: json)) == false
        expect(JSON.init(json: json)) == json
    }

    func testJSONDecodableParsing() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<Headers,Int> = tron.request(path: "headers")
        let expectation = expectationWithDescription("Parsing headers response")
        request.performWithSuccess({ headers in
            if headers.host == "httpbin.org" {
                expectation.fulfill()
            }
        })
        
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testJSONDecodableWorksWithSiblings() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<Sibling,Int> = tron.request(path: "headers")
        let expectation = expectationWithDescription("Parsing headers response")
        request.performWithSuccess({ sibling in
            if sibling.foo == "4" {
                expectation.fulfill()
            }
        })
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
