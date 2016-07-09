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
        return bundle.urlForResource(fileName, withExtension: withExtension)!
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
        let expectation = self.expectation(withDescription: "Upload from file")
        request.perform(success: { result in
            if let dictionary = result.response["headers"] as? [String:String] {
                if dictionary["Content-Length"] == "2592" {
                    expectation.fulfill()
                }
            }
            }, failure: { _ in
            XCTFail()
        })
        waitForExpectations(withTimeout: 5, handler: nil)
    }
    
    
    func testUploadData() {
        let data = "foo".data(using: String.Encoding.utf8)
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "/post", data: data!)
        request.method = .POST
        let expectation = self.expectation(withDescription: "Upload data")
        request.perform(success: { result in
            if let dictionary = result.response["form"] as? [String:String] {
                if dictionary.keys.first == "foo" {
                    expectation.fulfill()
                }
            }
            }, failure: { _ in
                XCTFail()
        })
        waitForExpectations(withTimeout: 5, handler: nil)
    }
    
    func testUploadFromStream() {
        let imageURL = URLForResource("cat", withExtension: "jpg")
        let imageStream = InputStream(url: imageURL)!
        
        let request: APIRequest<TestResponse,TronError> = tron.upload(path: "/post", stream: imageStream)
        request.method = .POST
        let expectation = self.expectation(withDescription: "Upload stream")
        request.perform(success: { result in
            if let dictionary = result.response["headers"] as? [String:String] {
                if dictionary["Content-Length"] == "2592" {
                    expectation.fulfill()
                }
            }
            }, failure: { _ in
                XCTFail()
        })
        waitForExpectations(withTimeout: 5, handler: nil)
    }
    
    func testMultipartUploadWorks() {
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.uploadMultipart(path: "post") { formData in
            formData.appendBodyPart(data: "bar".data(using: .utf8) ?? Data(), name: "foo")
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
    
    func testMultipartUploadIsAbleToUploadFile() {
        let path = Bundle(for: self.dynamicType).pathForResource("cat", ofType: "jpg")
        let data = try? Data(contentsOf: URL(fileURLWithPath: path ?? ""))
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.uploadMultipart(path: "post") { formData in
            formData.appendBodyPart(data: data ?? Data(),name: "cat", mimeType: "image/jpeg")
        }
        request.method = .POST
        
        let catExpectation = expectation(withDescription: "meau!")
        
        request.performMultipart(success: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["cat"] != nil {
                    catExpectation.fulfill()
                }
            }
        })
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testIntParametersAreAcceptedAsMultipartParameters() {
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.uploadMultipart(path: "post") { $0 }
        request.method = .POST
        request.parameters = ["foo":1]
        
        let expectation = self.expectation(withDescription: "Int expectation")
        request.performMultipart(success: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["foo"] == "1" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testBoolParametersAreAcceptedAsMultipartParameters() {
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.uploadMultipart(path: "post") { $0 }
        request.method = .POST
        request.parameters = ["foo":true]
        
        let expectation = self.expectation(withDescription: "Int expectation")
        
        request.performMultipart(success: {
            if let dictionary = $0.response["form"] as? [String:String] {
                if dictionary["foo"] == "1" {
                    expectation.fulfill()
                }
            }
        })
        waitForExpectations(withTimeout: 10, handler: nil)
    }
}
