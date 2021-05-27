//
//  ApiStubbingTestCase.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import TRON
import TRONSwiftyJSON
import XCTest
import SwiftyJSON

struct TestUser: JSONDecodable {
    let name: String
    let id: Int

    init(json: JSON) {
        id = json["id"].intValue
        name = json["name"].stringValue
    }
}

func userData(id: Int, name: String) -> Data {
    return (try? JSONSerialization.data(withJSONObject: ["id": id, "name": name], options: [.prettyPrinted])) ?? .init()
}

private struct ErrorThrow: Error {}

private class ThrowingJSONDecodable: JSONDecodable {
    required init(json: JSON) throws {
        throw ErrorThrow()
    }
}

class ApiStubbingTestCase: XCTestCase {

    let tron = TRON(baseURL: "https://github.com")

    func testStubsSuccessWork() {
        let request: APIRequest<TestUser, APIError> = tron.swiftyJSON
            .request("f00")
            .stub(with: .init(data: userData(id: 5, name: "Foo")))

        let exp = expectation(description: "Stubs success")
        request.perform(withSuccess: { response in
            XCTAssertEqual(response.id, 5)
            XCTAssertEqual(response.name, "Foo")
            exp.fulfill()
            }) { error in
                XCTFail("unexpected network error: \(error)")
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStubsFailureWorks() {
        let request: APIRequest<ThrowingJSONDecodable, APIError> = tron.swiftyJSON
            .request("f00")
            .stub(with: .init(data: String(5).data(using: .utf8)))
        let exp = expectation(description: "Stubs fails")
        request.perform(withSuccess: { _ in
            XCTFail("Failure expected but success was received")
            }) { error in
                XCTAssertEqual(error.data?.asString, "5")
                exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMultipartStubbingSuccessWorks() {
        let request: UploadAPIRequest<TestUser, APIError> = tron.swiftyJSON
            .uploadMultipart("f00") { _ in
            }
            .stub(with: APIStub(data: userData(id: 3, name: "Bar")))

        let exp = expectation(description: "multipart stubbing success")
        request.perform(withSuccess: { model in
            if model.id == 3, model.name == "Bar" { exp.fulfill() }
            }, failure: { error in
            XCTFail("unexpected network error: \(error)")
        })
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDownloadStubbingWorks() throws {
        let destination = Alamofire.DownloadRequest.suggestedDownloadDestination()
        let serializer = TRONDownloadResponseSerializer { _, _, url, _ -> Int in
            if url?.absoluteString == "expected.pkg" { return 0 }
            return 1
        }
        let request: DownloadAPIRequest<Int, APIError> = tron
            .download("path", to: destination, responseSerializer: serializer)
            .stub(with: APIStub(fileURL: URL(string: "expected.pkg")))
        let exp = expectation(description: "stub with completion handler")
        request.performCollectingTimeline(withCompletion: { response in
            XCTAssertEqual(try? response.result.get(), 0)
            exp.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testStubbingSuccessfullyWorksWithCompletionHandler() {
        let request: APIRequest<Int, JSONDecodableError<Int>> = tron
            .swiftyJSON(readingOptions: .allowFragments)
            .request("f00")
            .stub(with: APIStub(data: String(5).data(using: .utf8)))

        let exp = expectation(description: "stub with completion handler")
        request.performCollectingTimeline(withCompletion: { response in
            if (try? response.result.get()) == 5 {
                exp.fulfill()
            }
        })
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStubbingWorksAsynchronously() {
        let request: APIRequest<Int, APIError> = tron
            .swiftyJSON(readingOptions: .allowFragments)
            .request("f00")
            .stub(with: APIStub(data: String(5).data(using: .utf8)), delay: 0.2)
        var intResponse: Int?
        let exp = expectation(description: "Stubs success")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(intResponse)
        }
        request.perform(withSuccess: { response in
            intResponse = response
            XCTAssertEqual(response, 5)
            exp.fulfill()
        }) { error in
            XCTFail("unexpected network error: \(error)")
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
