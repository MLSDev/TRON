//
//  RxSwiftExtensionTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 19.04.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import RxSwift
import Alamofire

class RxSwiftExtensionTestCase: XCTestCase {
    
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "http://httpbin.org")
    }
    
    func testRxResultSuccessfullyCompletes() {
        let request : APIRequest<String,TronError> = tron.request(path: "get")
        let expectation = expectationWithDescription("200")
        _ = request.rxResult().subscribeNext { _ in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testRxResultIsClosedAfterSuccessfulResponse() {
        let request : APIRequest<String,TronError> = tron.request(path: "get")
        let expectation = expectationWithDescription("200")
        _ = request.rxResult().subscribeCompleted { _ in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testRxResultCanBeFailed() {
        let request : APIRequest<Int,TronError> = tron.request(path: "status/418")
        let expectation = expectationWithDescription("Teapot")
        _ = request.rxResult().subscribeError { _ in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testMultipartRxCanBeSuccessful() {
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "post") { formData in
            formData.appendBodyPart(data: "bar".dataUsingEncoding(NSUTF8StringEncoding) ?? NSData(), name: "foo")
        }
        request.method = .POST
        
        let expectation = expectationWithDescription("foo")
        
        _ = request.rxMultipartUpload().subscribeNext { result in
            if let dictionary = result.response["form"] as? [String:String] {
                if dictionary["foo"] == "bar" {
                    expectation.fulfill()
                }
            }
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
