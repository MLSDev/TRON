//
//  ResponseSerializationTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 24.09.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Alamofire
import TRON
import XCTest

protocol Food {}

struct Apple: Food {
}

struct Meat: Food {
}

struct FoodResponseSerializer: DataResponseSerializerProtocol {
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [Food] {
        return [Apple(), Meat()]
    }
}

class ResponseSerializationTestCase: ProtocolStubbedTestCase {

    func testAlamofireStringResponseSerializerIsAcceptedByTRON() {
        let serializer = StringResponseSerializer(encoding: .utf8, emptyResponseCodes: [200], emptyRequestMethods: [.get])
        let request: APIRequest<String, APIError> = tron
            .request("status/200", responseSerializer: serializer)
            .stubStatusCode(200)
        let expectation = self.expectation(description: "200")
        request.perform(withSuccess: { _ in
                expectation.fulfill()
        }) { error in
            XCTFail("unexpected network error: \(error)")
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testProtocolIsAcceptedWithCustomResponseSerializer() {
        let request: APIRequest<[Food], APIError> = tron
            .request("status/200", responseSerializer: FoodResponseSerializer())
        .stubStatusCode(200)
        let expectation = self.expectation(description: "200")
        request.perform(withSuccess: { model in
            if model.first is Apple && model.last is Meat {
                expectation.fulfill()
            }
        }) { error in
            XCTFail("unexpected network error: \(error)")
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
