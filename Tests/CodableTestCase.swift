//
//  CodableTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.06.17.
//  Copyright © 2017 Denys Telezhkin. All rights reserved.
//

import XCTest
@testable import TRON
import SwiftyJSON
import Alamofire

private struct CodableResponse : Codable {
    let title: String
}

class CodableTestCase: ProtocolStubbedTestCase {
    
    func testCodableParsing() {
        let request: APIRequest<CodableResponse,APIError> = tron.codable.request("test")
        let expectation = self.expectation(description: "Parsing headers response")
        request.stubSuccess(["title":"Foo"].asData)
        request.perform(withSuccess: { response in
            XCTAssertEqual(response.title, "Foo")
            expectation.fulfill()
        }, failure: { error in
            print(error)
        })
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCodableErrorParsing() {
        let request: APIRequest<Int,APIError> = tron.codable.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        request.stubStatusCode(418)
        request.perform(withSuccess: { _ in
            XCTFail()
        }) { error in
            XCTAssertEqual(error.response?.statusCode, 418)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testEmptyResponseStillCallsSuccessBlock() {
        let request : APIRequest<Empty, APIError> = tron.codable.request("headers")
        request.stubSuccess(.init())
        let expectation = self.expectation(description: "Empty response")
        request.perform(withSuccess: { _ in
            expectation.fulfill()
        }, failure: { _ in
            XCTFail()
            })
        waitForExpectations(timeout: 1, handler: nil)
    }
    
}
