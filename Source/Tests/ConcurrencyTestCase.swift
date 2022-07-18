//
//  AsyncTestCase.swift
//  Tests
//
//  Created by Denys Telezhkin on 09.07.2021.
//  Copyright © 2021 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import Alamofire

#if swift(>=5.5)

struct TestResponse: Codable {
    let value: Int
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
class AsyncTestCase: ProtocolStubbedTestCase {

    func testAsyncSuccessfullyCompletes() async throws {
        let request: APIRequest<TestResponse, APIError> = tron.codable.request("get").stubSuccess(["value":3].asData)
        let response = try await request.sender().value
        XCTAssertEqual(response.value, 3)
    }
    
    func testHandleCancellation() async throws {
        let request: APIRequest<String, APIError> = tron.codable.request("get").stubSuccess([:].asData)
        let handle = Task {
            try await request.sender().value
        }
        
        handle.cancel()
        do {
            let _ = try await handle.value
            XCTFail("should not receive response")
        } catch {
            XCTAssertNotNil(error as? APIError)
            XCTAssertTrue((error as? APIError)?.isCancelled ?? false)
            if !((error as? APIError)?.isCancelled ?? true) {
                XCTFail("received wrong error: \(error)")
                XCTFail("underlying error: \(error.localizedDescription)")
            }
        }
    }
    
    func testAsyncResultSuccess() async {
        let request: APIRequest<TestResponse, APIError> = tron.codable.request("get").stubSuccess(["value":3].asData)
        
        let result = await request.sender().result
        
        XCTAssertEqual(result.success?.value, 3)
    }
    
    func testAsyncResultFailure() async {
        let request: APIRequest<TestResponse, APIError> = tron.codable.request("get").stubFailure(URLError(.badURL))
        
        let result = await request.sender().result
        let afError = result.failure?.error as? AFError
        switch afError {
        case .sessionTaskFailed(error: let urlError):
            XCTAssertEqual((urlError as? URLError)?.code, URLError(.badURL).code)
        default:
            XCTFail("Unexpected error")
        }
    }
    
    func testAsyncResponse() async {
        let request: APIRequest<TestResponse, APIError> = tron.codable.request("get").stubSuccess(["value":3].asData)
        let response = await request.sender().response
        
        XCTAssertEqual(response.value?.value, 3)
    }
    
    func testConcurrentRequests() async throws {
        let request1: APIRequest<TestResponse, APIError> = tron.codable.request("get").stubSuccess(["value":1].asData)
        let request2: APIRequest<TestResponse, APIError> = tron.codable.request("get").stubSuccess(["value":2].asData)
        let request3: APIRequest<TestResponse, APIError> = tron.codable.request("get").stubSuccess(["value":3].asData)
        
        let values = try await [request1.sender().value, request2.sender().value, request3.sender().value].compactMap { $0.value }
        
        XCTAssertEqual(values, [1,2,3])
    }

    func testAsyncCanThrow() async {
        let request: APIRequest<Int, APIError> = tron.codable.request("status/418").stubStatusCode(URLError.resourceUnavailable.rawValue)
        
        do {
            try await _ = request.sender().value
            XCTFail("unexpected success")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Response status code was unacceptable: 16.")
        }
    }

    func testMultipartRxCanBeSuccessful() async throws {
        let request: UploadAPIRequest<JSONDecodableResponse, APIError> = tron.codable
           .uploadMultipart("post") { formData in
               formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
           }
           .post()
           .stubSuccess(["title": "Foo"].asData)
        
        let response = try await request.sender().value
        XCTAssertEqual(response.title, "Foo")
    }

    func testMultipartRxCanBeFailureful() async throws {
        let request: UploadAPIRequest<JSONDecodableResponse, APIError> = tron.codable
           .uploadMultipart("post") { formData in
               formData.append("bar".data(using: .utf8) ?? Data(), withName: "foo")
           }
           .delete()
           .stubStatusCode(200)
        do {
            let _ = try await request.sender().value
            XCTFail("Unexpected success")
        } catch {
            guard let decodingError = (error as? APIError)?.error as? DecodingError else {
                XCTFail("unexpected error type")
                return
            }
            switch decodingError {
            case .typeMismatch, .valueNotFound, .keyNotFound:
                XCTFail("unexpected error type")
            case .dataCorrupted: ()
            @unknown default: XCTFail("unexpected error type")
            }
        }
    }

    let searchPathDirectory = FileManager.SearchPathDirectory.cachesDirectory
    let searchPathDomain = FileManager.SearchPathDomainMask.userDomainMask

    func testDownloadRequest() async throws {
        let destination = Alamofire.DownloadRequest.suggestedDownloadDestination(
            for: searchPathDirectory,
            in: searchPathDomain
        )
        let request: DownloadAPIRequest<URL, APIError> = tron
            .download("/stream/100",
                      to: destination)
            .stubSuccess(.init(), statusCode: 200)
        
        let sender = request.sender()
        let result = await sender.result
        switch result {
        case .failure: ()
        case .success: ()
        }
    }
    
    func testDownloadAsyncFailure() async throws {
        let destination = Alamofire.DownloadRequest.suggestedDownloadDestination(
            for: searchPathDirectory,
            in: searchPathDomain
        )
        let responseSerializer = TRONDownloadResponseSerializer<URL?> { _, _, url, _ in throw "Fail" }
        let request: DownloadAPIRequest<URL?, APIError> = tron
            .download("/stream/100",
                      to: destination,
                      responseSerializer: responseSerializer)
            .stubSuccess(.init(), statusCode: 200)
        do {
            _ = try await request.sender().value
            XCTFail("Unexpected success")
        } catch {
            XCTAssertEqual((error as? APIError)?.error as? String, "Fail")
        }
    }
}

#endif
