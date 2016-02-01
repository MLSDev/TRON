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

class JSONDecodableTestCase: XCTestCase {
    let tron = TRON(baseURL: "https://github.com")
    
    func testDecodableArray() {
        let request: APIRequest<[Int],TronError> = tron.request(path: "foo")
        let json = JSON([1,2,3,4])
        let parsedResponse = request.responseBuilder.buildResponseFromJSON(json)
        
        expect(parsedResponse) == [1,2,3,4]
    }

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
}
