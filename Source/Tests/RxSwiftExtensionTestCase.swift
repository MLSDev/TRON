//
//  RxSwiftExtensionTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 19.04.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import TRON
import RxTRON
import RxSwift
import Foundation
import XCTest

class RxSwiftExtensionTestCase: ProtocolStubbedTestCase {

    func testRxResultSuccessfullyCompletes() {
        let request: APIRequest<String, APIError> = tron.swiftyJSON.request("get").stubSuccess([:].asData)
        let expectation = self.expectation(description: "200")
        _ = request.rxResult().subscribe(onNext: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRxResultIsClosedAfterSuccessfulResponse() {
        let request: APIRequest<String, APIError> = tron.swiftyJSON.request("get").stubSuccess([:].asData)
        let expectation = self.expectation(description: "200")
        _ = request.rxResult().subscribe(onCompleted: {
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRxResultCanBeFailed() {
        let request: APIRequest<Int, APIError> = tron.swiftyJSON.request("status/418").stubStatusCode(418)
        let expectation = self.expectation(description: "Teapot")
        _ = request.rxResult().subscribe(onError: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMultipartRxCanBeSuccessful() {
        let request: UploadAPIRequest<JSONDecodableResponse, APIError> = tron.swiftyJSON
            .uploadMultipart("post") { formData in
                formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
            }
            .post()
            .stubSuccess(["title": "Foo"].asData)
        let expectation = self.expectation(description: "foo")

        _ = request.rxResult().subscribe(onNext: { result in
            XCTAssertEqual(result.title, "Foo")
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMultipartRxCanBeFailureful() {
        let request: UploadAPIRequest<JSONDecodableResponse, APIError> = tron.swiftyJSON
            .uploadMultipart("post") { formData in
                formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
            }
            .delete()
            .stubStatusCode(200)
        let expectation = self.expectation(description: "foo")
        _ = request.rxResult().subscribe(onError: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
}
