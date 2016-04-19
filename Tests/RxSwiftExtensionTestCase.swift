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
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testRxResultIsClosedAfterSuccessfulResponse() {
        let request : APIRequest<String,TronError> = tron.request(path: "get")
        let expectation = expectationWithDescription("200")
        _ = request.rxResult().subscribeCompleted { _ in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testRxResultCanBeFailed() {
        let request : APIRequest<Int,TronError> = tron.request(path: "status/418")
        let expectation = expectationWithDescription("Teapot")
        _ = request.rxResult().subscribeError { _ in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testMultipartRxCanBeSuccessful() {
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.multipartRequest(path: "post")
        request.method = .POST
        request.appendMultipartData("bar".dataUsingEncoding(NSUTF8StringEncoding) ?? NSData(), name: "foo")
        
        let expectation = expectationWithDescription("foo")
        
        let (_,result) = request.rxUpload()
        
        _ = result.subscribeNext { result in
            if let dictionary = result.response["form"] as? [String:String] {
                if dictionary["foo"] == "bar" {
                    expectation.fulfill()
                }
            }
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testMultipartRxSendsProgress() {
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.multipartRequest(path: "post")
        request.method = .POST
        request.appendMultipartData("bar".dataUsingEncoding(NSUTF8StringEncoding) ?? NSData(), name: "foo")
        
        let expectation = expectationWithDescription("foo")
        
        let (progress,_) = request.rxUpload()
        
        _ = progress.subscribeNext { result in
            if result.totalBytesWritten > 0 {
                expectation.fulfill()
            }
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
