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
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.multipartRequest(path: "post")
        request.method = .POST
        request.appendMultipartData("bar".dataUsingEncoding(NSUTF8StringEncoding) ?? NSData(), name: "foo")
        
        let expectation = expectationWithDescription("foo")
        request.performWithSuccess( { result in
            if let dictionary = result.response["form"] as? [String:String] {
                if dictionary["foo"] == "bar" {
                    expectation.fulfill()
                }
            }
//                print(result)
            }, failure: { error in
//                print(error)
            }, progress: { progress in
//                print(progress)
            }, cancellableCallback: { token in })
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testMultipartUploadIsAbleToUploadFile() {
        let request: MultipartAPIRequest<TestResponse,TronError> = tron.multipartRequest(path: "post")
        request.method = .POST
        let path = NSBundle(forClass: self.dynamicType).pathForResource("cat", ofType: "jpg")
        let data = NSData(contentsOfFile: path ?? "")
        request.appendMultipartData(data ?? NSData(),name: "cat", mimeType: "image/jpeg")
        
        let catExpectation = expectationWithDescription("meau!")
        request.performWithSuccess( { result in
            if let dictionary = result.response["form"] as? [String:String] {
                if dictionary["cat"] != nil {
                    catExpectation.fulfill()
                }
            }
            print(result.response)
            
            }, failure: { error in
//                print(error)
            }, progress: { progress in
//                print(progress)
            }, cancellableCallback: { token in })
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
