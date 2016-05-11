//
//  MultipartAPIRequestTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 19.04.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import SwiftyJSON

class TestResponse : JSONDecodable {
    let response : [String:AnyObject]
    
    required init(json: JSON) {
        response = json.dictionaryObject ?? [:]
    }
}

class MultipartAPIRequestTestCase: XCTestCase {
    
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "https://httpbin.org")
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
