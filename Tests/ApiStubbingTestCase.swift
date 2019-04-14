//
//  ApiStubbingTestCase.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import XCTest
@testable import TRON
import SwiftyJSON
import Alamofire

struct TestUser : JSONDecodable {
    let name: String
    let id: Int
    
    init(json: JSON) {
        id = json["id"].intValue
        name = json["name"].stringValue
    }
}

private func userData(id: Int, name: String) -> Data {
    return try! JSONSerialization.data(withJSONObject: ["id": id, "name": name], options: [.prettyPrinted])
}

fileprivate struct ErrorThrow: Error {}

fileprivate class ThrowingJSONDecodable : JSONDecodable {
    required init(json: JSON) throws {
        throw ErrorThrow()
    }
}

class ApiStubbingTestCase: XCTestCase {
    
    let tron = TRON(baseURL: "https://github.com")
    
    func testStubsSuccessWork() {
        let request: APIRequest<TestUser,APIError> = tron.swiftyJSON.request("f00")
        request.apiStub = APIStub(data: userData(id: 5, name: "Foo"))
        request.apiStub?.isEnabled = true
        
        let exp = expectation(description: "Stubs success")
        request.perform(withSuccess: { response in
            XCTAssertEqual(response.id, 5)
            XCTAssertEqual(response.name, "Foo")
            exp.fulfill()
            }) { error in
                XCTFail()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStubsFailureWorks() {
        let request : APIRequest<ThrowingJSONDecodable,APIError> = tron.swiftyJSON.request("f00")
        request.apiStub = APIStub(data: String(5).data(using:  .utf8))
        request.apiStub?.isEnabled = true
        
        let exp = expectation(description: "Stubs fails")
        request.perform(withSuccess: { response in
            XCTFail()
            }) { error in
                XCTAssertEqual(error.data?.asString, "5")
                exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testMultipartStubbingSuccessWorks() {
        let request: UploadAPIRequest<TestUser,APIError> = tron.swiftyJSON.uploadMultipart("f00") { formData in
        }
        request.apiStub = APIStub(data: userData(id: 3, name: "Bar"))
        request.apiStub?.isEnabled = true
        
        let exp = expectation(description: "multipart stubbing success")
        request.perform(withSuccess: { model in
            if model.id == 3, model.name == "Bar" { exp.fulfill() }
            }, failure: { error in
                XCTFail()
        })
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadStubbingWorks() throws {
        let destination = Alamofire.DownloadRequest.suggestedDownloadDestination()
        let serializer = TRONDownloadResponseSerializer { (_, _, url, _) -> Int in
            if url?.absoluteString == "expected.pkg" { return 0 }
            return 1
        }
        let request: DownloadAPIRequest<Int, APIError> = tron.download("path", to: destination, responseSerializer: serializer)
        request.apiStub = APIStub(fileURL: URL(string: "expected.pkg"))
        request.apiStub?.isEnabled = true
        let exp = expectation(description: "stub with completion handler")
        request.performCollectingTimeline(withCompletion: { response in
            XCTAssertEqual(try? response.result.get(), 0)
            exp.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testStubbingSuccessfullyWorksWithCompletionHandler() {
        let parser = tron.swiftyJSON
        parser.options = .allowFragments
        let request: APIRequest<Int,JSONDecodableError<Int>> = parser.request("f00")
        request.apiStub = APIStub(data: String(5).data(using: .utf8))
        request.apiStub?.isEnabled = true
        
        let exp = expectation(description: "stub with completion handler")
        request.performCollectingTimeline(withCompletion: { response in
            if (try? response.result.get()) == 5 {
                exp.fulfill()
            }
        })
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStubbingWorksAsynchronously() {
        let parser = tron.swiftyJSON
        parser.options = .allowFragments
        let request: APIRequest<Int,APIError> = parser.request("f00")
        request.apiStub = APIStub(data: String(5).data(using: .utf8))
        request.apiStub?.isEnabled = true
        request.apiStub?.stubDelay = 0.2
        var intResponse: Int? = nil
        let exp = expectation(description: "Stubs success")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(intResponse)
        }
        request.perform(withSuccess: { response in
            intResponse = response
            XCTAssertEqual(response, 5)
            exp.fulfill()
        }) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
