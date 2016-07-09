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
    
    required init(json: JSON) {
        response = json.dictionaryObject ?? [:]
    }
}

class APIRequestTestCase: XCTestCase {
    
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "http://httpbin.org")
    }
    
    func testErrorBuilding() {
        let request: APIRequest<Int,TronError> = tron.request(path: "status/418")
        let expectation = self.expectation(withDescription: "Teapot")
        request.perform(success: { _ in
            XCTFail()
        }) { error in
            if error.response?.statusCode == 418 {
                expectation.fulfill()
            }
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testSuccessCallBackIsCalledOnMainThread() {
        let request : APIRequest<String,TronError> = tron.request(path: "get")
        let expectation = self.expectation(withDescription: "200")
        request.perform(success: { _ in
            if Thread.isMainThread {
                expectation.fulfill()
            }
            }) { _ in
            XCTFail()
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testFailureCallbackIsCalledOnMainThread() {
        let request : APIRequest<Int,TronError> = tron.request(path: "status/418")
        let expectation = self.expectation(withDescription: "Teapot")
        request.perform(success: { _ in
            XCTFail()
        }) { error in
            if Thread.isMainThread {
                expectation.fulfill()
            }
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testParsingFailureCallbackIsCalledOnMainThread() {
        let request : APIRequest<Int,TronError> = tron.request(path: "html")
        let expectation = self.expectation(withDescription: "Parsing failure")
        request.perform(success: { _ in
            XCTFail()
        }) { error in
            if Thread.isMainThread {
                expectation.fulfill()
            }
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testSuccessBlockCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = DispatchQueue.global(attributes: [.qosBackground])
        let request : APIRequest<Int,TronError> = tron.request(path: "get")
        let expectation = self.expectation(withDescription: "200")
        request.perform(success: { _ in
            if !Thread.isMainThread {
                expectation.fulfill()
            }
            }) { _ in
                XCTFail()
            }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testFailureCallbacksCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = DispatchQueue.global(attributes: [.qosBackground])
        let request : APIRequest<Int,TronError> = tron.request(path: "html")
        let expectation = self.expectation(withDescription: "Parsing failure")
        request.perform(success: { _ in
            XCTFail()
            }) { error in
                if !Thread.isMainThread {
                    expectation.fulfill()
                }
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testEmptyResponseStillCallsSuccessBlock() {
        let request : APIRequest<EmptyResponse, TronError> = tron.request(path: "headers")
        request.method = .HEAD
        let expectation = self.expectation(withDescription: "Empty response")
        request.perform(success: { _ in
                expectation.fulfill()
            }, failure: { _ in
                XCTFail()
            }
        )
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testRequestWillStartEvenIfStartAutomaticallyIsFalse()
    {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders
        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false
        let tron = TRON(baseURL: "http://httpbin.org", manager: manager)
        let request : APIRequest<EmptyResponse, TronError> = tron.request(path: "headers")
        request.method = .HEAD
        let expectation = self.expectation(withDescription: "Empty response")
        request.perform(success: { _ in
            expectation.fulfill()
            }, failure: { _ in
                XCTFail()
            }
        )
        waitForExpectations(withTimeout: 5, handler: nil)
    }
    
    func testMultipartUploadWillStartEvenIfStartAutomaticallyIsFalse() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders
        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false
        let tron = TRON(baseURL: "http://httpbin.org", manager: manager)
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.uploadMultipart(path: "post") { formData in
            formData.appendBodyPart(data: "bar".data(using: String.Encoding.utf8) ?? Data(), name: "foo")
        }
        request.method = .POST
        
        let expectation = self.expectation(withDescription: "foo")
        
        request.performMultipart(success: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["foo"] == "bar" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
}
