//
//  HeaderBuilderTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 31.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import Nimble
import Alamofire

class HeaderBuilderTestCase: XCTestCase {
    
    func testTronRequestHeaderBuilderAppendsHeaders() {
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<Int,TronError> = tron.request("status/200")
        request.headers = ["If-Modified-Since":"Sat, 29 Oct 1994 19:43:31 GMT"]
        
        let alamofireRequest = request.perform({ _ in })
        
        let headers = alamofireRequest?.request?.allHTTPHeaderFields
        
        expect(headers?["Accept"]) == "application/json"
        expect(headers?["If-Modified-Since"]) == "Sat, 29 Oct 1994 19:43:31 GMT"
    }
    
}
