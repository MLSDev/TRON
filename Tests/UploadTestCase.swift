//
//  UploadTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 13.05.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import XCTest
import TRON

extension XCTestCase {
    func URLForResource(fileName: String, withExtension: String) -> NSURL {
        let bundle = NSBundle(forClass: UploadTestCase.self)
        return bundle.URLForResource(fileName, withExtension: withExtension)!
    }
}

class UploadTestCase: XCTestCase {
    
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "http://httpbin.org")
    }
    
    func testUploadFromFile() {
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "/post", file: URLForResource("cat", withExtension: "jpg"))
        request.method = .POST
        let expectation = expectationWithDescription("Upload from file")
        request.perform(success: { result in
            if let dictionary = result.response["headers"] as? [String:String] {
                if dictionary["Content-Length"] == "2592" {
                    expectation.fulfill()
                }
            }
            }, failure: { _ in
            XCTFail()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    
    func testUploadData() {
        let data = "foo".dataUsingEncoding(NSUTF8StringEncoding)
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "/post", data: data!)
        request.method = .POST
        let expectation = expectationWithDescription("Upload data")
        request.perform(success: { result in
            if let dictionary = result.response["form"] as? [String:String] {
                if dictionary.keys.first == "foo" {
                    expectation.fulfill()
                }
            }
            }, failure: { _ in
                XCTFail()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testUploadFromStream() {
        let imageURL = URLForResource("cat", withExtension: "jpg")
        let imageStream = NSInputStream(URL: imageURL)!
        
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "/post", stream: imageStream)
        request.method = .POST
        let expectation = expectationWithDescription("Upload stream")
        request.perform(success: { result in
            if let dictionary = result.response["headers"] as? [String:String] {
                if dictionary["Content-Length"] == "2592" {
                    expectation.fulfill()
                }
            }
            }, failure: { _ in
                XCTFail()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
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
