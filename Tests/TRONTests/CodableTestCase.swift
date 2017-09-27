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

#if swift (>=4.0)

private struct HeadersResponse : Codable {
    
    let headers: Headers
    
    struct Headers : Codable {
        let host: String
        
        enum CodingKeys : String, CodingKey {
            case host = "Host"
        }
    }
}
    
fileprivate struct CodableError: Codable {
    
}

class CodableTestCase: XCTestCase {
    
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
    
    func testCodableErrorParsing() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<Int,CodableError> = tron.codable.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        request.perform(withSuccess: { _ in
            XCTFail()
        }) { error in
            if error.response?.statusCode == 418 {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}

#endif
