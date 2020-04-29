//
//  APIRequestTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import TRON
import XCTest

extension Data {
    var asString: String {
        return String(data: self, encoding: .utf8) ?? ""
    }
}

extension String {
    var asData: Data {
        return data(using: .utf8) ?? Data()
    }
}

extension Dictionary {
    var asData: Data {
        return (try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)) ?? Data()
    }
}

struct TimeoutInterceptor: RequestInterceptor {
    let timeoutInterval: TimeInterval
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.timeoutInterval = timeoutInterval
        completion(.success(urlRequest))
    }
}

class APIRequestTestCase: ProtocolStubbedTestCase {

    func testErrorBuilding() {
        let request: APIRequest<Int, APIError> = tron.swiftyJSON.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        request.stubSuccess("Teapot".asData)
            .perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
        }) { error in
            XCTAssertEqual(error.data?.asString, "Teapot")
            expectation.fulfill()
            }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSuccessCallBackIsCalledOnMainThread() {
        let request: APIRequest<String, APIError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request
            .stubSuccess([:].asData)
            .perform(withSuccess: { _ in
                XCTAssert(Thread.isMainThread)
                expectation.fulfill()
            }) { error in
                XCTFail("unexpected network error: \(error)")
            }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFailureCallbackIsCalledOnMainThread() {
        let request: APIRequest<Int, APIError> = tron.swiftyJSON.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        request.stubFailure().perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
        }) { _ in
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testParsingFailureCallbackIsCalledOnMainThread() {
        let request: APIRequest<Int, APIError> = tron.swiftyJSON.request("html")
        let expectation = self.expectation(description: "Parsing failure")
        request.stubFailure().perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
        }) { _ in
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3)
    }

    func testSuccessBlockCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = DispatchQueue.global(qos: .background)
        let request: APIRequest<Int, APIError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.stubSuccess([:].asData).perform(withSuccess: { _ in
            XCTAssertFalse(Thread.isMainThread)
            DispatchQueue.main.async {
                expectation.fulfill()
            }
            }) { error in
                XCTFail("unexpected network error: \(error)")
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFailureCallbacksCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = DispatchQueue.global(qos: .background)
        let request: APIRequest<Int, APIError> = tron.swiftyJSON.request("html")
        let expectation = self.expectation(description: "Parsing failure")
        request.stubFailure().perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
            }) { _ in
            XCTAssertFalse(Thread.isMainThread)
            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testRequestWithCompletionIsCalledOnMainThread() {
        let request: APIRequest<Int, APIError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.stubSuccess([:].asData).performCollectingTimeline { _ in
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testRequestWithCompletionCanBeCalledOnBackgroundThread() {
        let request: APIRequest<Int, APIError> = tron.swiftyJSON.request("get")
        request.resultDeliveryQueue = DispatchQueue.global(qos: .background)
        let expectation = self.expectation(description: "200")
        request.stubSuccess([:].asData).performCollectingTimeline { _ in
            XCTAssertFalse(Thread.isMainThread)
            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testEmptyResponseStillCallsSuccessBlock() {
        let request: APIRequest<Empty, APIError> = tron.swiftyJSON.request("headers").stubSuccess(.init())
        let expectation = self.expectation(description: "Empty response")
        request.perform(withSuccess: { _ in
                expectation.fulfill()
            }, failure: { error in
                XCTFail("unexpected network error: \(error)")
            }
        )
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testRequestWillStartEvenIfStartAutomaticallyIsFalse() {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.protocolClasses = [StubbingURLProtocol.self]
        let session = Session(configuration: configuration, startRequestsImmediately: false)
        let tron = TRON(baseURL: "https://httpbin.org", session: session)
        let request: APIRequest<Empty, APIError> = tron.swiftyJSON.request("headers").stubSuccess(.init())
        let expectation = self.expectation(description: "Empty response")
        request.perform(withSuccess: { _ in
            expectation.fulfill()
            }, failure: { error in
                XCTFail("unexpected network error: \(error)")
            }
        )
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMultipartUploadWillStartEvenIfStartAutomaticallyIsFalse() {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.protocolClasses = [StubbingURLProtocol.self]
        let session = Session(configuration: configuration, startRequestsImmediately: false)
        let tron = TRON(baseURL: "https://httpbin.org", session: session)
        let request: UploadAPIRequest<JSONDecodableResponse, APIError> = tron.swiftyJSON.uploadMultipart("post") { formData in
            formData.append("bar".data(using: String.Encoding.utf8) ?? Data(), withName: "foo")
        }.post().stubSuccess(["title": "not empty"].asData)

        let expectation = self.expectation(description: "foo")

        request.perform(withSuccess: { result in
            XCTAssertEqual(result.title, "not empty")
            expectation.fulfill()
        }, failure: { error in
            XCTFail("unexpected network error: \(error)")
        })
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCustomValidationClosure() {
        let request: APIRequest<Int, APIError> = tron.swiftyJSON.request("status/201")
        _ = request
            .validation { $0.validate(statusCode: (202..<203)) }
            .stubSuccess([:].asData, statusCode: 201)
        let expectation = self.expectation(description: "success")
        request.perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
        }) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCustomValidationClosureOverridesError() {
        let request: APIRequest<Empty, APIError> = tron.swiftyJSON.request("status/418")
        _ = request.validation { $0.validate(statusCode: (418...420)) }.stubSuccess([:].asData, statusCode: 418)
        let expectation = self.expectation(description: "We like tea from this teapot")
        request.perform(withSuccess: { _ in
            expectation.fulfill()
        }) { error in
            XCTFail("unexpected network error: \(error)")
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRequestCanAdapt() {
        let request: APIRequest<Empty, APIError> = tron.swiftyJSON
            .request("status/200")
            .intercept(using: TimeoutInterceptor(timeoutInterval: 3))
            .stubStatusCode(200)
        let expectation = self.expectation(description: "Success request")
        let resultingRequest = request.perform(withSuccess: { _ in
            expectation.fulfill()
        }) { error in
            XCTFail("unexpected network error: \(error)")
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(resultingRequest.task?.currentRequest?.timeoutInterval, 3)
    }
}
