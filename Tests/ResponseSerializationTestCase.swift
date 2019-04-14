//
//  ResponseSerializationTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 24.09.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import Alamofire
import SwiftyJSON

protocol Food {}

struct Apple : Food {
}

struct Meat : Food {
}

struct FoodResponseSerializer : DataResponseSerializerProtocol {
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [Food] {
        return [Apple(), Meat()]
    }
}

class ResponseSerializationTestCase: ProtocolStubbedTestCase {
    
    func testAlamofireStringResponseSerializerIsAcceptedByTRON() {
        let serializer = StringResponseSerializer(encoding: .utf8, emptyResponseCodes: [200], emptyRequestMethods: [.get])
        let request : APIRequest<String, APIError> = tron.request("status/200", responseSerializer: serializer)
        let expectation = self.expectation(description: "200")
        request.stubStatusCode(200)
        request.perform(withSuccess: { model in
                expectation.fulfill()
        }) { error in
            XCTFail()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testProtocolIsAcceptedWithCustomResponseSerializer() {
        let request : APIRequest<[Food], APIError> = tron.request("status/200", responseSerializer: FoodResponseSerializer())
        let expectation = self.expectation(description: "200")
        request.stubStatusCode(200)
        request.perform(withSuccess: { model in
            if model.first is Apple && model.last is Meat {
                expectation.fulfill()
            }
        }) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
}
