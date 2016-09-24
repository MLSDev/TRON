//
//  ResponseSerializationTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 24.09.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import Nimble
import Alamofire
import SwiftyJSON

extension Alamofire.DataResponseSerializer : ErrorHandlingDataResponseSerializerProtocol {
    public typealias SerializedError = TronError
    public var serializeError: (Result<SerializedObject>?, URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<SerializedError> {
        return { erroredResponse, request, response, data, error in
            return APIError(request: request,response: response,data: data,error: error)
        }
    }
}

protocol Food {}

struct Apple : Food {
}

struct Meat : Food {
}

struct FoodResponseSerializer : ErrorHandlingDataResponseSerializerProtocol {
    public typealias SerializedError = TronError
    public typealias SerializedObject = Array<Food>
    
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<SerializedObject> {
        return { request, response, data, error in
            return .success([Apple(),Meat()])
        }
    }
    
    public var serializeError: (Result<SerializedObject>?,URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<SerializedError> {
        return { erroredResponse, request, response, data, error in
            return APIError(request: request,response: response,data: data,error: error)
        }
    }
}

class ResponseSerializationTestCase: XCTestCase {
    
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "http://httpbin.org")
    }
    
    func testAlamofireStringResponseSerializerIsAcceptedByTRON() {
        let request : APIRequest<String, TronError> = tron.request("status/200", responseSerializer: DataRequest.stringResponseSerializer(encoding: .utf8))
        let expectation = self.expectation(description: "200")
        request.perform(withSuccess: { model in
                expectation.fulfill()
        }) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testProtocolIsAcceptedWithCustomResponseSerializer() {
        let request : APIRequest<[Food], TronError> = tron.request("status/200", responseSerializer: FoodResponseSerializer())
        let expectation = self.expectation(description: "200")
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
