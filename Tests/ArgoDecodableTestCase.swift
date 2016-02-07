//
//  ArgoDecodableTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 07.02.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
//import Argo
//import Curry
//
//private struct ArgoHeaders : Argo.Decodable, ResponseParseable {
//    
//    let host : String
//    
//    static func decode(j: JSON) -> Decoded<ArgoHeaders> {
//        return curry(ArgoHeaders.init)
//        <^> j <| "host"
//    }
//}
//
//class ArgoDecodableTestCase: XCTestCase {
//    
//    func testArgoDecodableParsing() {
//        let tron = TRON(baseURL: "http://httpbin.org")
//        let request: APIRequest<ArgoHeaders,Int> = tron.request(path: "headers")
//        let expectation = expectationWithDescription("Parsing headers response")
//        request.performWithSuccess({ headers in
//            if headers.host == "httpbin.org" {
//                expectation.fulfill()
//            }
//        })
//        
//        waitForExpectationsWithTimeout(3, handler: nil)
//    }
//}
