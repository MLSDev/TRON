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
}
