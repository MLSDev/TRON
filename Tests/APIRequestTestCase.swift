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

class APIRequestTestCase: XCTestCase {
    
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "http://httpbin.org")
    }
    
    func testErrorBuilding() {
        let request: APIRequest<Int,TronError> = tron.request(path: "status/418")
        let expectation = expectationWithDescription("Teapot")
        request.perform(success: { _ in
            XCTFail()
        }) { error in
            if error.response?.statusCode == 418 {
                expectation.fulfill()
            }
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testSuccessCallBackIsCalledOnMainThread() {
        let request : APIRequest<String,TronError> = tron.request(path: "get")
        let expectation = expectationWithDescription("200")
        request.perform(success: { _ in
            if NSThread.isMainThread() {
                expectation.fulfill()
            }
            }) { _ in
            XCTFail()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testFailureCallbackIsCalledOnMainThread() {
        let request : APIRequest<Int,TronError> = tron.request(path: "status/418")
        let expectation = expectationWithDescription("Teapot")
        request.perform(success: { _ in
            XCTFail()
        }) { error in
            if NSThread.isMainThread() {
                expectation.fulfill()
            }
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testParsingFailureCallbackIsCalledOnMainThread() {
        let request : APIRequest<Int,TronError> = tron.request(path: "html")
        let expectation = expectationWithDescription("Parsing failure")
        request.perform(success: { _ in
            XCTFail()
        }) { error in
            if NSThread.isMainThread() {
                expectation.fulfill()
            }
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testSuccessBlockCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        let request : APIRequest<Int,TronError> = tron.request(path: "get")
        let expectation = expectationWithDescription("200")
        request.perform(success: { _ in
            if !NSThread.isMainThread() {
                expectation.fulfill()
            }
            }) { _ in
                XCTFail()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testFailureCallbacksCanBeCalledOnBackgroundThread() {
        tron.resultDeliveryQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        let request : APIRequest<Int,TronError> = tron.request(path: "html")
        let expectation = expectationWithDescription("Parsing failure")
        request.perform(success: { _ in
            XCTFail()
            }) { error in
                if !NSThread.isMainThread() {
                    expectation.fulfill()
                }
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testEmptyResponseStillCallsSuccessBlock() {
        let request : APIRequest<EmptyResponse, TronError> = tron.request(path: "headers")
        request.method = .HEAD
        let expectation = expectationWithDescription("Empty response")
        request.perform(success: { _ in
                expectation.fulfill()
            }, failure: { _ in
                XCTFail()
            }
        )
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}
