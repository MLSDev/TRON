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
        let request : APIRequest<String,TronError> = tron.request("get")
        let expectation = self.expectation(description: "200")
        _ = request.rx.result().subscribe(onNext: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRxResultIsClosedAfterSuccessfulResponse() {
        let request : APIRequest<String,TronError> = tron.request("get")
        let expectation = self.expectation(description: "200")
        _ = request.rx.result().subscribe(onCompleted: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRxResultCanBeFailed() {
        let request : APIRequest<Int,TronError> = tron.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        _ = request.rx.result().subscribe(onError: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testMultipartRxCanBeSuccessful() {
        let request: UploadAPIRequest<TestResponse,TronError> = tron.uploadMultipart("post") { formData in
            formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
        }
        request.method = .post
        
        let expectation = self.expectation(description: "foo")
        
        _ = request.rx.multipartResult().subscribe(onNext: { result in
            if let dictionary = result.response["form"] as? [String:String] {
                if dictionary["foo"] == "bar" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testMultipartRxCanBeFailureful() {
        let request: UploadAPIRequest<TestResponse,TronError> = tron.uploadMultipart("post") { formData in
            formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
        }
        request.method = .delete
        let expectation = self.expectation(description: "foo")
        
        _ = request.rx.multipartResult().subscribe(onError: { error in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
}
