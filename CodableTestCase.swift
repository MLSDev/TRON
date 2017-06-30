//
//  CodableTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.06.17.
//  Copyright © 2017 Denys Telezhkin. All rights reserved.
//

import XCTest
@testable import TRON
import Nimble
import SwiftyJSON
import Alamofire

private struct HeadersResponse : Codable {
    
    let headers: Headers
    
    struct Headers : Codable {
        let host: String
        
        enum CodingKeys : String, CodingKey {
            case host = "Host"
        }
    }
}

class CodableTestCase: XCTestCase {
    
    #if swift (>=4.0)
    
    func testCodableParsing() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<HeadersResponse,Int> = tron.codable.request("headers")
        let expectation = self.expectation(description: "Parsing headers response")
        request.perform(withSuccess:  { headers in
            if headers.headers.host == "httpbin.org" {
                expectation.fulfill()
            }
        }, failure: { error in
            print(error)
        })
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    #endif
    
}
