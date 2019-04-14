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
import Alamofire

class DownloadTestCase: ProtocolStubbedTestCase {
    
    let searchPathDirectory = FileManager.SearchPathDirectory.cachesDirectory
    let searchPathDomain = FileManager.SearchPathDomainMask.userDomainMask
    
    func testDownloadRequest() {
        // Given
        
        let destination = Alamofire.DownloadRequest.suggestedDownloadDestination(
            for: searchPathDirectory,
            in: searchPathDomain
        )
        let responseSerializer = TRONDownloadResponseSerializer { _,_, url,_ in url }
        let request: DownloadAPIRequest<URL?, APIError> = tron.download("/stream/100",
                                                                                 to: destination,
                                                                                 responseSerializer: responseSerializer)
        request.stubSuccess(.init(), statusCode: 200)
        let expectation = self.expectation(description: "Download expectation")
        request.performCollectingTimeline(withCompletion: { result in
            XCTAssertEqual(result.response?.statusCode, 200)
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
}
