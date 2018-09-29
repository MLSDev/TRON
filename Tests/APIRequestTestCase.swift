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
//        let configuration = URLSessionConfiguration()
//        configuration.protocolClasses = [StubbingURLProtocol.self] as [AnyClass]
        tron = TRON(baseURL: "http://httpbin.org")
//            , manager: SessionManager(configuration: configuration))
//        URLProtocol.registerClass(StubbingURLProtocol.self)
    }
    
    func testErrorBuilding() {
        let request: APIRequest<Int,TronError> = tron.swiftyJSON.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        request.perform(withSuccess: { _ in
            XCTFail()
        }) { error in
            if error.response?.statusCode == 418 {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSuccessCallBackIsCalledOnMainThread() {
        let request : APIRequest<String,TronError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.perform(withSuccess: { _ in
            if Thread.isMainThread {
                expectation.fulfill()
            }
            }) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testFailureCallbackIsCalledOnMainThread() {
        let request : APIRequest<Int,TronError> = tron.swiftyJSON.request("status/418")
        let expectation = self.expectation(description: "Teapot")
        request.perform(withSuccess: { _ in
            XCTFail()
        }) { error in
            if Thread.isMainThread {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testParsingFailureCallbackIsCalledOnMainThread() {
        let request : APIRequest<Int,TronError> = tron.swiftyJSON.request("html")
        let expectation = self.expectation(description: "Parsing failure")
        request.perform(withSuccess: { _ in
            XCTFail()
        }) { error in
            if Thread.isMainThread {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testSuccessBlockCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = DispatchQueue.global(qos: .background)
        let request : APIRequest<Int,TronError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.perform(withSuccess: { _ in
            if !Thread.isMainThread {
                expectation.fulfill()
            }
            }) { _ in
                XCTFail()
            }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFailureCallbacksCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = DispatchQueue.global(qos: .background)
        let request : APIRequest<Int,TronError> = tron.swiftyJSON.request("html")
        let expectation = self.expectation(description: "Parsing failure")
        request.perform(withSuccess: { _ in
            XCTFail()
            }) { error in
                if !Thread.isMainThread {
                    expectation.fulfill()
                }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRequestWithCompletionIsCalledOnMainThread() {
        let request : APIRequest<Int,TronError> = tron.swiftyJSON.request("get")
        let expectation = self.expectation(description: "200")
        request.performCollectingTimeline { _ in
            if Thread.isMainThread { expectation.fulfill() }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRequestWithCompletionCanBeCalledOnBackgroundThread() {
        let request : APIRequest<Int,TronError> = tron.swiftyJSON.request("get")
        request.resultDeliveryQueue = DispatchQueue.global(qos: .background)
        let expectation = self.expectation(description: "200")
        request.performCollectingTimeline { _ in
            if !Thread.isMainThread { expectation.fulfill() }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testEmptyResponseStillCallsSuccessBlock() {
        let request : APIRequest<EmptyResponse, TronError> = tron.swiftyJSON.request("headers")
        request.method = .head
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
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        let manager = SessionManager(configuration: configuration)
        manager.startRequestsImmediately = false
        let tron = TRON(baseURL: "http://httpbin.org", manager: manager)
        let request : APIRequest<EmptyResponse, TronError> = tron.swiftyJSON.request("headers")
        request.method = .head
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
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        let manager = SessionManager(configuration: configuration)
        manager.startRequestsImmediately = false
        let tron = TRON(baseURL: "http://httpbin.org", manager: manager)
        let request: UploadAPIRequest<TestResponse,TronError> = tron.swiftyJSON.uploadMultipart("post") { formData in
            formData.append("bar".data(using: String.Encoding.utf8) ?? Data(), withName: "foo")
        }
        request.method = .post
        
        let expectation = self.expectation(description: "foo")
        
        request.performMultipart(withSuccess: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["foo"] == "bar" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCustomValidationClosure() {
        let request : APIRequest<Int,TronError> = tron.swiftyJSON.request("status/201")
        request.validationClosure = { $0.validate(statusCode: (202..<203)) }
        let expectation = self.expectation(description: "success")
        request.perform(withSuccess: { _ in
            XCTFail()
        }) { error in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCustomValidationClosureOverridesError() {
        let request : APIRequest<Int,TronError> = tron.swiftyJSON.request("status/418")
        request.validationClosure = { $0.validate(statusCode: (418...420)) }
        let expectation = self.expectation(description: "We like tea from this teapot")
        request.perform(withSuccess: { _ in
            expectation.fulfill()
        }) { error in
            XCTFail()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
