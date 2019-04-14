//
//  HeaderBuilderTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 31.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import Alamofire

class HeaderBuilderTestCase: ProtocolStubbedTestCase {
    
    func testTronRequestHeaderBuilderAppendsHeaders() {
        let request: APIRequest<Int,APIError> = tron.swiftyJSON.request("status/200")
        request.headers = ["If-Modified-Since":"Sat, 29 Oct 1994 19:43:31 GMT"]
        request.stubStatusCode(200)
        let waitingForRequest = expectation(description: "wait for request")
        let alamofireRequest = request.performCollectingTimeline(withCompletion: { _ in
            waitingForRequest.fulfill()
        })
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(alamofireRequest.request)
        let headers = alamofireRequest.request?.allHTTPHeaderFields
        
        XCTAssertEqual(headers?["If-Modified-Since"], "Sat, 29 Oct 1994 19:43:31 GMT")
    }
    
}
