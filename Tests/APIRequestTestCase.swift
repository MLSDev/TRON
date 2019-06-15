//
//  APIRequestTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

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

class APIRequestTestCase: ProtocolStubbedTestCase {
    
    func testErrorBuilding() {
        let request: APIRequest<Int,APIError> = tron.swiftyJSON.request("status/418")
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
        let request : APIRequest<String,APIError> = tron.swiftyJSON.request("get")
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
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        request.stubFailure().perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
        }) { error in
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testParsingFailureCallbackIsCalledOnMainThread() {
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("html")
        let expectation = self.expectation(description: "Parsing failure")
        request.stubFailure().perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
        }) { error in
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3)
    }
    
    func testSuccessBlockCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = DispatchQueue.global(qos: .background)
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("get")
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
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("html")
        let expectation = self.expectation(description: "Parsing failure")
        request.stubFailure().perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
            }) { error in
            XCTAssertFalse(Thread.isMainThread)
            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRequestWithCompletionIsCalledOnMainThread() {
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.stubSuccess([:].asData).performCollectingTimeline { _ in
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRequestWithCompletionCanBeCalledOnBackgroundThread() {
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("get")
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
        let request : APIRequest<Empty, APIError> = tron.swiftyJSON.request("headers").stubSuccess(.init())
        let expectation = self.expectation(description: "Empty response")
        request.perform(withSuccess: { _ in
                expectation.fulfill()
            }, failure: { error in
                XCTFail("unexpected network error: \(error)")
            }
        )
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRequestWillStartEvenIfStartAutomaticallyIsFalse()
    {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.protocolClasses = [StubbingURLProtocol.self]
        let manager = Session(configuration: configuration, startRequestsImmediately: false)
        let tron = TRON(baseURL: "https://httpbin.org", session: manager)
        let request : APIRequest<Empty, APIError> = tron.swiftyJSON.request("headers").stubSuccess(.init())
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
        let manager = Session(configuration: configuration, startRequestsImmediately: false)
        let tron = TRON(baseURL: "https://httpbin.org", session: manager)
        let request: UploadAPIRequest<JSONDecodableResponse,APIError> = tron.swiftyJSON.uploadMultipart("post") { formData in
            formData.append("bar".data(using: String.Encoding.utf8) ?? Data(), withName: "foo")
        }.post().stubSuccess(["title":"not empty"].asData)
        
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
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("status/201")
        _ = request
            .validation { $0.validate(statusCode: (202..<203))}
            .stubSuccess([:].asData, statusCode: 201)
        let expectation = self.expectation(description: "success")
        request.perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
        }) { error in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCustomValidationClosureOverridesError() {
        let request : APIRequest<Empty,APIError> = tron.swiftyJSON.request("status/418")
        _ = request.validation { $0.validate(statusCode: (418...420)) }.stubSuccess([:].asData, statusCode: 418)
        let expectation = self.expectation(description: "We like tea from this teapot")
        request.perform(withSuccess: { _ in
            expectation.fulfill()
        }) { error in
            XCTFail("unexpected network error: \(error)")
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
