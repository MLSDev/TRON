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

class ApiStubbingTestCase: XCTestCase {
    
    let tron = TRON(baseURL: "https://github.com")
    
    func testStubsSuccessWork() {
        let request: APIRequest<Int,TronError> = tron.request(path: "f00")
        request.stubbingEnabled = true
        request.apiStub.model = 5
        
        request.performWithSuccess({ response in
            expect(response) == 5
            }) { _ in
                XCTFail()
        }
    }
    
    func testStubsFailureWorks() {
        let request :APIRequest<Int,Int> = tron.request(path: "f00")
        request.stubbingEnabled = true
        request.apiStub.error = APIError<Int>(errorModel: 5)
        
        request.performWithSuccess({ response in
            XCTFail()
            }) { error in
             expect(error.errorModel) == 5
        }
    }
}
