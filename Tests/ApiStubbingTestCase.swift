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
        let request: APIRequest<Int,TronError> = tron.request(path: "f00")
        request.stubbingEnabled = true
        request.apiStub.model = 5
        
        request.perform(success: { response in
            expect(response) == 5
            }) { _ in
                XCTFail()
        }
    }
    
    func testStubsFailureWorks() {
        let request :APIRequest<Int,Int> = tron.request(path: "f00")
        request.stubbingEnabled = true
        request.apiStub.error = APIError<Int>(errorModel: 5)
        
        request.perform(success: { response in
            XCTFail()
            }) { error in
             expect(error.errorModel) == 5
        }
    }
    
    func testBuildingFromFileWorks() {
        let request :APIRequest<TestUser,TronError> = tron.request(path: "f00")
        request.stubbingEnabled = true
        request.apiStub.buildModelFromFile("user.json", inBundle: Bundle(for: self.dynamicType))
        
        expect(request.apiStub.model?.name) == "Alan Bradley"
        expect(request.apiStub.model?.id) == 1
    }
    
    func testMultipartStubbingSuccessWorks() {
        let request: MultipartAPIRequest<Int,TronError> = tron.uploadMultipart(path: "f00") { formData in
        }
        request.stubbingEnabled = true
        request.apiStub.model = 5
        
        request.performMultipart(success: { model in
            expect(model) == 5
            }, failure: { _ in
                XCTFail()
        })
    }
    
    func testStubbingSuccessfullyWorksWithCompletionHandler() {
        let request :APIRequest<Int,Int> = tron.request(path: "f00")
        request.stubbingEnabled = true
        request.apiStub.model = 5
        
        request.performCollectingTimeline(withCompletion: { response in
            expect(response.result.value) == 5
        })
    }
    
    func testStubbingFailurefullyWorksWithCompletionHandler() {
        let request :APIRequest<Int,Int> = tron.request(path: "f00")
        request.stubbingEnabled = true
        request.apiStub.error = APIError<Int>(errorModel: 5)
        
        request.performCollectingTimeline { response in
            expect(response.result.error?.errorModel) == 5
        }
    }
}
