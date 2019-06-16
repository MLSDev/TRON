//
//  CodableTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.06.17.
//  Copyright © 2017 Denys Telezhkin. All rights reserved.
//

import TRON
import Foundation
import XCTest
import Alamofire

private struct CodableResponse: Codable {
    let title: String
}

class CodableTestCase: ProtocolStubbedTestCase {

    func testCodableParsing() {
        let request: APIRequest<CodableResponse, APIError> = tron.codable.request("test").stubSuccess(["title": "Foo"].asData)
        let expectation = self.expectation(description: "Parsing headers response")
        request.perform(withSuccess: { response in
            XCTAssertEqual(response.title, "Foo")
            expectation.fulfill()
        }, failure: { error in
            print(error)
        })

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCodableErrorParsing() {
        let request: APIRequest<Int, APIError> = tron.codable.request("status/418").stubStatusCode(418)
        let expectation = self.expectation(description: "Teapot")
        request.perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
        }) { error in
            XCTAssertEqual(error.response?.statusCode, 418)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testEmptyResponseStillCallsSuccessBlock() {
        let request: APIRequest<Empty, APIError> = tron.codable.request("headers").stubSuccess(.init())
        let expectation = self.expectation(description: "Empty response")
        request.perform(withSuccess: { _ in
            expectation.fulfill()
        }, failure: { error in
            XCTFail("unexpected network error: \(error)")
            })
        waitForExpectations(timeout: 1, handler: nil)
    }

}
