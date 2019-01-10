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
    func URLForResource(_ fileName: String, withExtension: String) -> URL {
        let bundle = Bundle(for: UploadTestCase.self)
        return bundle.url(forResource:fileName, withExtension: withExtension)!
    }
}

class UploadTestCase: XCTestCase {
    
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "https://httpbin.org")
    }
    
    func testUploadFromFile() {
        let request: UploadAPIRequest<TestResponse,APIError> = tron.swiftyJSON.upload("/post", fromFileAt: URLForResource("cat", withExtension: "jpg"))
        request.method = .post
        let expectation = self.expectation(description: "Upload from file")
        request.perform(withSuccess: { result in
            if let dictionary = result.response["headers"] as? [String:String] {
                if dictionary["Content-Length"] == "2592" {
                    expectation.fulfill()
                }
            }
            }, failure: { _ in
            XCTFail()
        })
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    func testUploadData() {
        let data = "foo".data(using: String.Encoding.utf8)
        let request: UploadAPIRequest<TestResponse,APIError> = tron.swiftyJSON.upload("/post", data: data!)
        request.method = .post
        let expectation = self.expectation(description: "Upload data")
        request.perform(withSuccess: { result in
            if let dictionary = result.response["form"] as? [String:String] {
                if dictionary.keys.first == "foo" {
                    expectation.fulfill()
                }
            }
            }, failure: { _ in
                XCTFail()
        })
        waitForExpectations(timeout: 5, handler: nil)
    }
    
//    func testUploadFromStream() {
//        let imageURL = URLForResource("cat", withExtension: "jpg")
//        let imageStream = InputStream(url: imageURL)!
//        
//        let request: UploadAPIRequest<TestResponse,APIError> = tron.upload("/post", from: imageStream)
//        request.method = .post
//        let expectation = self.expectation(description: "Upload stream")
//        request.perform(withSuccess: { result in
//            if let dictionary = result.response["headers"] as? [String:String] {
//                // For some reason server is no longer reporting Content-Length header
////                if dictionary["Content-Length"] == "2592" {
//                    expectation.fulfill()
////                }
//            }
//            }, failure: { error in
//                XCTFail()
//        })
//        waitForExpectations(timeout: 5, handler: nil)
//    }
    
    func testMultipartUploadWorks() {
        let request: UploadAPIRequest<TestResponse,APIError> = tron.swiftyJSON.uploadMultipart("post") { formData in
            formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
        }
        request.method = .post
        
        let expectation = self.expectation(description: "foo")
        
        request.perform(withSuccess: {
            XCTAssertNotNil($0.response["data"])
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testMultipartUploadIsAbleToUploadFile() {
        let path = Bundle(for: type(of: self)).path(forResource: "cat", ofType: "jpg")
        let data = try? Data(contentsOf: URL(fileURLWithPath: path ?? ""))
        let request: UploadAPIRequest<TestResponse,APIError> = tron.swiftyJSON.uploadMultipart("post") { formData in
            formData.append(data ?? Data(), withName: "cat", mimeType: "image/jpeg")
        }
        request.method = .post
        
        let catExpectation = expectation(description: "meau!")
        
        request.perform(withSuccess: {
            XCTAssertNotNil($0.response["data"])
            catExpectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testIntParametersAreAcceptedAsMultipartParameters() {
        let request: UploadAPIRequest<TestResponse,APIError> = tron.swiftyJSON.uploadMultipart("post") { _ in }
        request.method = .post
        request.parameters = ["foo":1 as AnyObject]
        
        let expectation = self.expectation(description: "Int expectation")
        request.perform(withSuccess: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["foo"] == "1" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testBoolParametersAreAcceptedAsMultipartParameters() {
        let request: UploadAPIRequest<TestResponse,APIError> = tron.swiftyJSON.uploadMultipart("post") { _ in }
        request.method = .post
        request.parameters = ["foo":true as AnyObject]
        
        let expectation = self.expectation(description: "Int expectation")
        
        request.perform(withSuccess: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["foo"] == "1" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
}
