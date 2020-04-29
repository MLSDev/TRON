//
//  DownloadTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 14.05.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import XCTest
import TRON

class DownloadTestCase: ProtocolStubbedTestCase {

    let searchPathDirectory = FileManager.SearchPathDirectory.cachesDirectory
    let searchPathDomain = FileManager.SearchPathDomainMask.userDomainMask

    func testDownloadRequest() {
        let destination = Alamofire.DownloadRequest.suggestedDownloadDestination(
            for: searchPathDirectory,
            in: searchPathDomain
        )
        let responseSerializer = TRONDownloadResponseSerializer { _, _, url, _ in url }
        let request: DownloadAPIRequest<URL?, APIError> = tron
            .download("/stream/100",
                      to: destination,
                      responseSerializer: responseSerializer)
            .stubSuccess(.init(), statusCode: 200)
        let expectation = self.expectation(description: "Download expectation")
        request.performCollectingTimeline(withCompletion: { result in
            XCTAssertEqual(result.response?.statusCode, 200)
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRequestCanAdapt() {
        let destination = Alamofire.DownloadRequest.suggestedDownloadDestination(
            for: searchPathDirectory,
            in: searchPathDomain
        )
        let responseSerializer = TRONDownloadResponseSerializer { _, _, url, _ in url }
        let request: DownloadAPIRequest<URL?, APIError> = tron
            .download("/stream/100",
                      to: destination,
                      responseSerializer: responseSerializer)
            .intercept(using: TimeoutInterceptor(timeoutInterval: 3))
            .stubSuccess(.init(), statusCode: 200)
        let expectation = self.expectation(description: "Download expectation")
        let resultingRequest = request.performCollectingTimeline(withCompletion: { result in
            XCTAssertEqual(result.response?.statusCode, 200)
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(resultingRequest.task?.currentRequest?.timeoutInterval, 3)
    }
    
    func testDownloadSuccessBlock() {
        let destination = Alamofire.DownloadRequest.suggestedDownloadDestination(
            for: searchPathDirectory,
            in: searchPathDomain
        )
        let responseSerializer = TRONDownloadResponseSerializer { _, _, url, _ in url }
        let request: DownloadAPIRequest<URL?, APIError> = tron
            .download("/stream/100",
                      to: destination,
                      responseSerializer: responseSerializer)
            .stubSuccess(.init(), statusCode: 200)
        let expectation = self.expectation(description: "Download expectation")
        request.perform(withSuccess: { url in
            expectation.fulfill()
        }) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDownloadFailureBlock() {
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
        let expectation = self.expectation(description: "Download expectation")
        request.perform(withSuccess: { url in
            XCTFail()
        }) { error in
            XCTAssertEqual(error.error as? String, "Fail")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}

extension String: Error {}
