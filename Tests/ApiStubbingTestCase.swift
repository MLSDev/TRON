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
import SwiftyJSON3

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
        request.apiStub.model = 5
        
        request.perform(withSuccess: { response in
            expect(response) == 5
            }) { _ in
                XCTFail()
        }
    }
    
    func testStubsFailureWorks() {
        let request :APIRequest<Int,Int> = tron.request("f00")
        request.stubbingEnabled = true
        request.apiStub.error = APIError<Int>(errorModel: 5)
        
        request.perform(withSuccess: { response in
            XCTFail()
            }) { error in
             expect(error.errorModel) == 5
        }
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
        request.apiStub.model = 5
        
        request.performMultipart(withSuccess: { model in
            expect(model) == 5
            }, failure: { _ in
                XCTFail()
        })
    }
    
    func testStubbingSuccessfullyWorksWithCompletionHandler() {
        let request :APIRequest<Int,Int> = tron.request("f00")
        request.stubbingEnabled = true
        request.apiStub.model = 5
        
        request.performCollectingTimeline(withCompletion: { response in
            expect(response.result.value) == 5
        })
    }
    
    func testStubbingFailurefullyWorksWithCompletionHandler() {
        let request :APIRequest<Int,Int> = tron.request("f00")
        request.stubbingEnabled = true
        request.apiStub.error = APIError<Int>(errorModel: 5)
        
        request.performCollectingTimeline { response in
            expect((response.result.error as? APIError<Int>)?.errorModel) == 5
        }
    }
}
