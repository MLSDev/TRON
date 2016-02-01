//
//  APIRequestTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import Nimble

class APIRequestTestCase: XCTestCase {
    
    func testErrorBuilding() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<Int,TronError> = tron.request(path: "status/418")
        let expectation = expectationWithDescription("Teapot")
        request.performWithSuccess({ _ in
            XCTFail()
        }) { error in
            if error.response?.statusCode == 418 {
                expectation.fulfill()
            }
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
}
