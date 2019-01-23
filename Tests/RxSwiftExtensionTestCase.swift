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

class RxSwiftExtensionTestCase: ProtocolStubbedTestCase {
    
    func testRxResultSuccessfullyCompletes() {
        let request : APIRequest<String,APIError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.stubSuccess([:].asData)
        _ = request.rxResult().subscribe(onNext: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRxResultIsClosedAfterSuccessfulResponse() {
        let request : APIRequest<String,APIError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.stubSuccess([:].asData)
        _ = request.rxResult().subscribe(onCompleted: { 
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRxResultCanBeFailed() {
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        request.stubStatusCode(418)
        _ = request.rxResult().subscribe(onError: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testMultipartRxCanBeSuccessful() {
        let request: UploadAPIRequest<JSONDecodableResponse,APIError> = tron.swiftyJSON.uploadMultipart("post") { formData in
            formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
        }
        request.method = .post
        request.stubSuccess(["title":"Foo"].asData)
        let expectation = self.expectation(description: "foo")
        
        _ = request.rxResult().subscribe(onNext: { result in
            XCTAssertEqual(result.title, "Foo")
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testMultipartRxCanBeFailureful() {
        let request: UploadAPIRequest<JSONDecodableResponse,APIError> = tron.swiftyJSON.uploadMultipart("post") { formData in
            formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
        }
        request.method = .delete
        request.stubStatusCode(400)
        let expectation = self.expectation(description: "foo")
        
        _ = request.rxResult().subscribe(onError: { error in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
}
