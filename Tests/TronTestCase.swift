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
import Alamofire

class TronTestCase: XCTestCase {
    
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "https://github.com")
    }
    
    override func tearDown() {
        super.tearDown()
        tron = nil
    }
    
    func testTronRequestBuildables() {
        let request: APIRequest<Int,APIError> = tron.swiftyJSON.request("/foo")
        
        let tronBuilder = tron.urlBuilder as? URLBuilder
        let requestBuilder = request.urlBuilder as? URLBuilder
        expect(requestBuilder === tronBuilder).to(beTruthy())
    }
}
