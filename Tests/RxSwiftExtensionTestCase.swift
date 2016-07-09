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
        let expectation = self.expectation(withDescription: "200")
        _ = request.rxResult().subscribeNext { _ in
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testRxResultIsClosedAfterSuccessfulResponse() {
        let request : APIRequest<String,TronError> = tron.request(path: "get")
        let expectation = self.expectation(withDescription: "200")
        _ = request.rxResult().subscribeCompleted { _ in
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testRxResultCanBeFailed() {
        let request : APIRequest<Int,TronError> = tron.request(path: "status/418")
        let expectation = self.expectation(withDescription: "Teapot")
        _ = request.rxResult().subscribeError { _ in
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testMultipartRxCanBeSuccessful() {
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.uploadMultipart(path: "post") { formData in
            formData.appendBodyPart(data: "bar".data(using: .utf8) ?? Data(), name: "foo")
        }
        request.method = .POST
        
        let expectation = self.expectation(withDescription: "foo")
        
        _ = request.rxMultipartResult().subscribeNext { result in
            if let dictionary = result.response["form"] as? [String:String] {
                if dictionary["foo"] == "bar" {
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testMultipartRxCanBeFailureful() {
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.uploadMultipart(path: "post") { formData in
            formData.appendBodyPart(data: "bar".data(using: .utf8) ?? Data(), name: "foo")
        }
        
        let expectation = self.expectation(withDescription: "foo")
        
        _ = request.rxMultipartResult().subscribeError { error in
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
}
