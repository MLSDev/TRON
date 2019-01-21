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
import Alamofire
import SwiftyJSON

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

class TestResponse : JSONDecodable {
    let response : [String:AnyObject]
    
    required init(json: JSON) throws {
        response = json.dictionaryObject as [String : AnyObject]? ?? [:]
    }
}

class APIRequestTestCase: XCTestCase {
    
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [StubbingURLProtocol.self]
        tron = TRON(baseURL: "https://httpbin.org", manager: Session(configuration: configuration))
        URLProtocol.registerClass(StubbingURLProtocol.self)
    }
    
    func testErrorBuilding() {
        let request: APIRequest<Int,APIError> = tron.swiftyJSON.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        request.stubSuccess("Teapot".asData)
        request.perform(withSuccess: { _ in
            XCTFail()
        }) { error in
            XCTAssertEqual(error.data?.asString, "Teapot")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSuccessCallBackIsCalledOnMainThread() {
        let request : APIRequest<String,APIError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.stubSuccess([:].asData)
        request.perform(withSuccess: { _ in
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
            }) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFailureCallbackIsCalledOnMainThread() {
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        request.stubFailure()
        request.perform(withSuccess: { _ in
            XCTFail()
        }) { error in
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testParsingFailureCallbackIsCalledOnMainThread() {
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("html")
        let expectation = self.expectation(description: "Parsing failure")
        request.stubFailure()
        request.perform(withSuccess: { _ in
            XCTFail()
        }) { error in
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testSuccessBlockCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = DispatchQueue.global(qos: .background)
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.stubSuccess([:].asData)
        request.perform(withSuccess: { _ in
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
            }) { _ in
                XCTFail()
            }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFailureCallbacksCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = DispatchQueue.global(qos: .background)
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("html")
        let expectation = self.expectation(description: "Parsing failure")
        request.stubFailure()
        request.perform(withSuccess: { _ in
            XCTFail()
            }) { error in
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRequestWithCompletionIsCalledOnMainThread() {
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.stubSuccess([:].asData)
        request.performCollectingTimeline { _ in
            XCTAssert(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRequestWithCompletionCanBeCalledOnBackgroundThread() {
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("get")
        request.resultDeliveryQueue = DispatchQueue.global(qos: .background)
        let expectation = self.expectation(description: "200")
        request.stubSuccess([:].asData)
        request.performCollectingTimeline { _ in
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testEmptyResponseStillCallsSuccessBlock() {
        let request : APIRequest<EmptyResponse, APIError> = tron.swiftyJSON.request("headers")
        request.stubSuccess(.init())
        let expectation = self.expectation(description: "Empty response")
        request.perform(withSuccess: { _ in
                expectation.fulfill()
            }, failure: { _ in
                XCTFail()
            }
        )
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRequestWillStartEvenIfStartAutomaticallyIsFalse()
    {
        let configuration = URLSessionConfiguration.default
        configuration.httpHeaders = .default
        configuration.protocolClasses = [StubbingURLProtocol.self]
        let manager = Session(startRequestsImmediately: false, configuration: configuration)
        let tron = TRON(baseURL: "https://httpbin.org", manager: manager)
        let request : APIRequest<EmptyResponse, APIError> = tron.swiftyJSON.request("headers")
        request.stubSuccess(.init())
        let expectation = self.expectation(description: "Empty response")
        request.perform(withSuccess: { _ in
            expectation.fulfill()
            }, failure: { _ in
                XCTFail()
            }
        )
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testMultipartUploadWillStartEvenIfStartAutomaticallyIsFalse() {
        let configuration = URLSessionConfiguration.default
        configuration.httpHeaders = .default
        configuration.protocolClasses = [StubbingURLProtocol.self]
        let manager = Session(startRequestsImmediately: false, configuration: configuration)
        let tron = TRON(baseURL: "https://httpbin.org", manager: manager)
        let request: UploadAPIRequest<TestResponse,APIError> = tron.swiftyJSON.uploadMultipart("post") { formData in
            formData.append("bar".data(using: String.Encoding.utf8) ?? Data(), withName: "foo")
        }
        request.method = .post
        request.stubSuccess(["data":"not empty"].asData)
        let expectation = self.expectation(description: "foo")
        
        request.perform(withSuccess: { result in
            XCTAssertNotNil(result.response["data"])
            expectation.fulfill()
        }, failure: { error in
            XCTFail("Successful request failed")
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCustomValidationClosure() {
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("status/201")
        request.validationClosure = { $0.validate(statusCode: (202..<203)) }
        request.stubSuccess([:].asData, statusCode: 201)
        let expectation = self.expectation(description: "success")
        request.perform(withSuccess: { _ in
            XCTFail()
        }) { error in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCustomValidationClosureOverridesError() {
        let request : APIRequest<EmptyResponse,APIError> = tron.swiftyJSON.request("status/418")
        request.validationClosure = { $0.validate(statusCode: (418...420)) }
        let expectation = self.expectation(description: "We like tea from this teapot")
        request.stubSuccess([:].asData, statusCode: 418)
        request.perform(withSuccess: { _ in
            expectation.fulfill()
        }) { error in
            XCTFail()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
