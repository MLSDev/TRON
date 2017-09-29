//
//  ApiStubbingTestCase.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import XCTest
@testable import TRON
import Nimble
import SwiftyJSON

struct TestUser : JSONDecodable {
    let name: String
    let id: Int
    
    init(json: JSON) {
        id = json["id"].intValue
        name = json["name"].stringValue
    }
}

fileprivate struct ErrorThrow: Error {}

fileprivate class ThrowingJSONDecodable : JSONDecodable {
    required init(json: JSON) throws {
        throw ErrorThrow()
    }
}

class ApiStubbingTestCase: XCTestCase {
    
    let tron = TRON(baseURL: "https://github.com")
    
    func testStubsSuccessWork() {
        let parser = tron.swiftyJSON
        parser.options = .allowFragments
        let request: APIRequest<Int,TronError> = parser.request("f00")
        request.stubbingEnabled = true
        request.apiStub.successData = String(5).data(using: .utf8)
        
        let exp = expectation(description: "Stubs success")
        request.perform(withSuccess: { response in
            expect(response) == 5
            exp.fulfill()
            }) { _ in
                XCTFail()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStubsFailureWorks() {
        let parser = tron.swiftyJSON
        parser.options = .allowFragments
        let request :APIRequest<Int,Int> = parser.request("f00")
        request.stubbingEnabled = true
        request.apiStub.successful = false
        request.apiStub.errorData = String(5).data(using:  .utf8)
        
        let exp = expectation(description: "Stubs fails")
        request.perform(withSuccess: { response in
            XCTFail()
            }) { error in
             expect(error.errorModel) == 5
                exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testBuildingFromFileWorks() {
        let request :APIRequest<TestUser,TronError> = tron.swiftyJSON.request("f00")
        request.stubbingEnabled = true
        request.apiStub.buildModel(fromFileNamed: "user.json", inBundle: Bundle(for: type(of: self)))
        
        expect(request.apiStub.modelClosure()?.name) == "Alan Bradley"
        expect(request.apiStub.modelClosure()?.id) == 1
    }
    
    func testMultipartStubbingSuccessWorks() {
        let parser = tron.swiftyJSON
        parser.options = .allowFragments
        let request: UploadAPIRequest<Int,TronError> = parser.uploadMultipart("f00") { formData in
        }
        request.stubbingEnabled = true
        request.apiStub.successData = String(5).data(using: .utf8)
        
        let exp = expectation(description: "multipart stubbing success")
        request.performMultipart(withSuccess: { model in
            if model == 5 { exp.fulfill() }
            }, failure: { _ in
                XCTFail()
        })
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStubbingSuccessfullyWorksWithCompletionHandler() {
        let parser = tron.swiftyJSON
        parser.options = .allowFragments
        let request :APIRequest<Int,Int> = parser.request("f00")
        request.stubbingEnabled = true
        request.apiStub.successData = String(5).data(using: .utf8)
        
        let exp = expectation(description: "stub with completion handler")
        request.performCollectingTimeline(withCompletion: { response in
            if response.result.value == 5 {
                exp.fulfill()
            }
        })
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStubbingFailurefullyWorksWithCompletionHandler() {
        let parser = tron.swiftyJSON
        parser.options = .allowFragments
        let request :APIRequest<Int,Int> = parser.request("f00")
        request.stubbingEnabled = true
        request.apiStub.successful = false
        request.apiStub.errorData = String(5).data(using:  .utf8)
        
        request.performCollectingTimeline { response in
            expect((response.result.error as? APIError<Int>)?.errorModel) == 5
        }
    }
    
    func testStubbingWorksAsynchronously() {
        let parser = tron.swiftyJSON
        parser.options = .allowFragments
        let request: APIRequest<Int,TronError> = parser.request("f00")
        request.stubbingEnabled = true
        request.apiStub.stubDelay = 0.2
        request.apiStub.successData = String(5).data(using: .utf8)
        
        let exp = expectation(description: "Stubs success")
        request.perform(withSuccess: { response in
            expect(response) == 5
            exp.fulfill()
        }) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStubWithThrowingDataShouldCallFailureBlock() {
        let request : APIRequest<ThrowingJSONDecodable,TronError> = tron.swiftyJSON.request("f00")
        request.stubbingEnabled = true
        let exp = expectation(description: "Stubs construction failure")
        request.perform(withSuccess: { response in
            XCTFail()
        }) { _ in
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStubWithThrowingDataShouldCallFailureCompletionBlock() {
        let request : APIRequest<ThrowingJSONDecodable,TronError> = tron.swiftyJSON.request("f00")
        request.stubbingEnabled = true
        let exp = expectation(description: "Stubs construction failure")
        request.performCollectingTimeline { result in
            if result.result.isFailure {
                exp.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
