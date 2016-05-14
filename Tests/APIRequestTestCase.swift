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
    
    func testRequestWillStartEvenIfStartAutomaticallyIsFalse()
    {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false
        let tron = TRON(baseURL: "http://httpbin.org", manager: manager)
        let request : APIRequest<EmptyResponse, TronError> = tron.request(path: "headers")
        request.method = .HEAD
        let expectation = expectationWithDescription("Empty response")
        request.perform(success: { _ in
            expectation.fulfill()
            }, failure: { _ in
                XCTFail()
            }
        )
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testMultipartUploadWillStartEvenIfStartAutomaticallyIsFalse() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false
        let tron = TRON(baseURL: "http://httpbin.org", manager: manager)
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "post") { formData in
            formData.appendBodyPart(data: "bar".dataUsingEncoding(NSUTF8StringEncoding) ?? NSData(), name: "foo")
        }
        request.method = .POST
        
        let expectation = expectationWithDescription("foo")
        
        request.performMultipartUpload(success: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["foo"] == "bar" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testMultipartUploadWorks() {
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "post") { formData in
            formData.appendBodyPart(data: "bar".dataUsingEncoding(NSUTF8StringEncoding) ?? NSData(), name: "foo")
        }
        request.method = .POST
        
        let expectation = expectationWithDescription("foo")
        
        request.performMultipartUpload(success: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["foo"] == "bar" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testMultipartUploadIsAbleToUploadFile() {
        let path = NSBundle(forClass: self.dynamicType).pathForResource("cat", ofType: "jpg")
        let data = NSData(contentsOfFile: path ?? "")
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "post") { formData in
            formData.appendBodyPart(data: data ?? NSData(),name: "cat", mimeType: "image/jpeg")
        }
        request.method = .POST
        
        let catExpectation = expectationWithDescription("meau!")
        
        request.performMultipartUpload(success: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["cat"] != nil {
                    catExpectation.fulfill()
                }
            }
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testIntParametersAreAcceptedAsMultipartParameters() {
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "post") { $0 }
        request.method = .POST
        request.parameters = ["foo":1]
        
        let expectation = expectationWithDescription("Int expectation")
        request.performMultipartUpload(success: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["foo"] == "1" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testBoolParametersAreAcceptedAsMultipartParameters() {
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "post") { $0 }
        request.method = .POST
        request.parameters = ["foo":true]
        
        let expectation = expectationWithDescription("Int expectation")
        
        request.performMultipartUpload(success: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["foo"] == "1" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
