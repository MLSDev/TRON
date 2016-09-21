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

class ApiStubbingTestCase: XCTestCase {
    
    let tron = TRON(baseURL: "https://github.com")
    
    func testStubsSuccessWork() {
        let request: APIRequest<Int,TronError> = tron.request("f00")
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
        let request :APIRequest<Int,Int> = tron.request("f00")
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
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testBuildingFromFileWorks() {
        let request :APIRequest<TestUser,TronError> = tron.request("f00")
        request.stubbingEnabled = true
        request.apiStub.buildModel(fromFileNamed: "user.json", inBundle: Bundle(for: type(of: self)))
        
        expect(request.apiStub.model?.name) == "Alan Bradley"
        expect(request.apiStub.model?.id) == 1
    }
    
    func testMultipartStubbingSuccessWorks() {
        let request: UploadAPIRequest<Int,TronError> = tron.uploadMultipart("f00") { formData in
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
        let request :APIRequest<Int,Int> = tron.request("f00")
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
        let request :APIRequest<Int,Int> = tron.request("f00")
        request.stubbingEnabled = true
        request.apiStub.successful = false
        request.apiStub.errorData = String(5).data(using:  .utf8)
        
        request.performCollectingTimeline { response in
            expect((response.result.error as? APIError<Int>)?.errorModel) == 5
        }
    }
}
