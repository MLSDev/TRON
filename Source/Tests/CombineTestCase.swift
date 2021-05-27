//
//  CombineTestCase.swift
//  Tests
//
//  Created by Denys Telezhkin on 15.06.2020.
//  Copyright © 2020 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
#if canImport(Combine)
import Combine
#endif

extension Result {
    var success: Success? {
        try? get()
    }
    
    var failure: Failure? {
        switch self {
            case .failure(let error): return error
            case .success: return nil
        }
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension Subscribers.Completion {
    var failure: Failure? {
        switch self {
            case .finished: return nil
            case .failure(let error): return error
        }
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
class CombineTestCase: ProtocolStubbedTestCase {
    
    var tokens: Set<AnyCancellable> = .init()

    func testRxResultSuccessfullyCompletes() {
        let request: APIRequest<String, APIError> = tron.swiftyJSON.request("get").stubSuccess([:].asData)
        let expectation = self.expectation(description: "200")
        request.publisher().sink(receiveCompletion: { completion in
        }) { value in
            expectation.fulfill()
        }.store(in: &tokens)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRxResultIsClosedAfterSuccessfulResponse() {
        let request: APIRequest<String, APIError> = tron.swiftyJSON.request("get").stubSuccess([:].asData)
        let expectation = self.expectation(description: "200")
        request.publisher().sink(receiveCompletion: { completion in
            expectation.fulfill()
        }) { value in
            
        }.store(in: &tokens)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRxResultCanBeFailed() {
        let request: APIRequest<Int, APIError> = tron.swiftyJSON.request("status/418").stubStatusCode(418)
        let expectation = self.expectation(description: "Teapot")

        request.publisher()
            .sink(receiveCompletion: { completion in
                if let error = completion.failure, error.response?.statusCode == 418 {
                    expectation.fulfill()
                }
        }) { value in
            XCTFail()
        }.store(in: &tokens)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMultipartRxCanBeSuccessful() {
        let request: UploadAPIRequest<JSONDecodableResponse, APIError> = tron.swiftyJSON
           .uploadMultipart("post") { formData in
               formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
           }
           .post()
           .stubSuccess(["title": "Foo"].asData)
        let expectation = self.expectation(description: "foo")

        request.publisher().sink(receiveCompletion: { _ in
            
        }) { result in
            XCTAssertEqual(result.title, "Foo")
            expectation.fulfill()
        }.store(in: &tokens)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMultipartRxCanBeFailureful() {
        let request: UploadAPIRequest<JSONDecodableResponse, APIError> = tron.swiftyJSON
           .uploadMultipart("post") { formData in
               formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
           }
           .delete()
           .stubStatusCode(200)
        let expectation = self.expectation(description: "foo")
        request.publisher().sink(receiveCompletion: { completion in
            if let _ = completion.failure {
                expectation.fulfill()
            }
        }) { _ in
            XCTFail()
        }.store(in: &tokens)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCombineStubs() {
        let request: APIRequest<TestUser, APIError> = tron.swiftyJSON
            .request("f00")
            .stub(with: .init(data: userData(id: 5, name: "Foo")))

        let exp = expectation(description: "Stubs success")
        request.publisher().sink(receiveCompletion: { completion in
            exp.fulfill()
        }) { user in
            XCTAssertEqual(user.id, 5)
            XCTAssertEqual(user.name, "Foo")
        }.store(in: &tokens)
        waitForExpectations(timeout: 3, handler: nil)
    }
}
