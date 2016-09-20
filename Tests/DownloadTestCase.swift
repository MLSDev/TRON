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
import Nimble

class DownloadTestCase: XCTestCase {
    
    let searchPathDirectory = FileManager.SearchPathDirectory.cachesDirectory
    let searchPathDomain = FileManager.SearchPathDomainMask.userDomainMask
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "http://httpbin.org")
    }
    
    func testDownloadRequest() {
        // Given
        
        let destination = Alamofire.DownloadRequest.suggestedDownloadDestination(
            for: searchPathDirectory,
            in: searchPathDomain
        )
        let request: DownloadAPIRequest<TronError> = tron.download("/stream/100", to: destination)
        let expectation = self.expectation(description: "Download expectation")
        request.performCollectingTimeline(withCompletion: { result in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 5, handler: nil)
        
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: searchPathDirectory, in: self.searchPathDomain)[0]
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            #if os(iOS) || os(tvOS)
                let suggestedFilename = "100"
            #elseif os(OSX)
                let suggestedFilename = "100.json"
            #endif
            
            let predicate = NSPredicate(format: "lastPathComponent = '\(suggestedFilename)'")
            let filteredContents = (contents as NSArray).filtered(using: predicate)
            XCTAssertEqual(filteredContents.count, 1, "should have one file in Documents")
            
            if let file = filteredContents.first as? URL {
                XCTAssertEqual(
                    file.lastPathComponent,
                    "\(suggestedFilename)",
                    "filename should be \(suggestedFilename)"
                )
                
                if let data = try? Data(contentsOf: file) {
                    XCTAssertGreaterThan(data.count, 0, "data length should be non-zero")
                } else {
                    XCTFail("data should exist for contents of URL")
                }
                
                do {
                    try fileManager.removeItem(at: file)
                } catch {
                    XCTFail("file manager should remove item at URL: \(file)")
                }
            } else {
                XCTFail("file should not be nil")
            }
        } catch {
            XCTFail("contents should not be nil")
        }
    }
    
    func testResumableDownload() {
        // Given
        tron = TRON(baseURL: "https://upload.wikimedia.org")
        
        let destination = Alamofire.DownloadRequest.suggestedDownloadDestination(
            for: searchPathDirectory,
            in: searchPathDomain
        )
        let path = "/wikipedia/commons/thumb/a/ab/Olympiastadion_at_dusk.JPG/2560px-Olympiastadion_at_dusk.JPG"
        let request: DownloadAPIRequest<TronError> = tron.download(path, to: destination)
        let expectation = self.expectation(description: "Download expectation")
        let alamofireRequest = request.performCollectingTimeline(withCompletion: { result in
            expectation.fulfill()
        })
        alamofireRequest?.downloadProgress { fraction in//_,_,_ in
            print("progress ",fraction)
            if fraction.fractionCompleted > 0.1 {
                alamofireRequest?.cancel()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
        
        guard let resumeData = alamofireRequest?.resumeData else {
            XCTFail("request should produce resume data")
            return
        }
        
        let continueDownloadRequest : DownloadAPIRequest<TronError> = tron.download(path, to: destination, resumingFrom : resumeData)
        let continueExpectation = self.expectation(description: "Continue download expectation")
        continueDownloadRequest.performCollectingTimeline(withCompletion: { result in
            continueExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 10, handler: nil)
        
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: searchPathDirectory, in: self.searchPathDomain)[0]
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            let suggestedFilename = "Olympiastadion_at_dusk.JPG"
            
            let predicate = NSPredicate(format: "lastPathComponent = '\(suggestedFilename)'")
            let filteredContents = (contents as NSArray).filtered(using: predicate)
            XCTAssertEqual(filteredContents.count, 1, "should have one file in Documents")
            
            if let file = filteredContents.first as? URL {
                XCTAssertEqual(
                    file.lastPathComponent,
                    "\(suggestedFilename)",
                    "filename should be \(suggestedFilename)"
                )
                
                if let data = try? Data(contentsOf: file) {
                    XCTAssertGreaterThan(data.count, 0, "data length should be non-zero")
                } else {
                    XCTFail("data should exist for contents of URL")
                }
                
                do {
                    try fileManager.removeItem(at: file)
                } catch {
                    XCTFail("file manager should remove item at URL: \(file)")
                }
            } else {
                XCTFail("file should not be nil")
            }
        } catch {
            XCTFail("contents should not be nil")
        }
    }
}
