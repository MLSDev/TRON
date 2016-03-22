//
//  TronTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 28.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import Nimble

class TronTestCase: XCTestCase {
    
    func testTronRequestBuildables() {
        let tron = TRON(baseURL: "https://github.com")
        let request: APIRequest<Int,TronError> = tron.request(path: "/foo")
        
        let tronBuilder = tron.urlBuilder as? URLBuilder
        let requestBuilder = request.urlBuilder as? URLBuilder
        expect(requestBuilder === tronBuilder).to(beTruthy())
    }
    
}
