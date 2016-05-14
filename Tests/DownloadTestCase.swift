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
    
    let searchPathDirectory = NSSearchPathDirectory.CachesDirectory
    let searchPathDomain = NSSearchPathDomainMask.UserDomainMask
    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "http://httpbin.org")
    }
    
    func testDownloadRequest() {
        // Given
        
        let destination = Alamofire.Request.suggestedDownloadDestination(
            directory: searchPathDirectory,
            domain: searchPathDomain
        )
        let request: APIRequest<EmptyResponse,TronError> = tron.download(path: "/stream/100", destination: destination)
        let expectation = expectationWithDescription("Download expectation")
        request.perform(completion: { result in
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
        
        let fileManager = NSFileManager.defaultManager()
        let directory = fileManager.URLsForDirectory(searchPathDirectory, inDomains: self.searchPathDomain)[0]
        
        do {
            let contents = try fileManager.contentsOfDirectoryAtURL(
                directory,
                includingPropertiesForKeys: nil,
                options: .SkipsHiddenFiles
            )
            
            #if os(iOS) || os(tvOS)
                let suggestedFilename = "100"
            #elseif os(OSX)
                let suggestedFilename = "100.json"
            #endif
            
            let predicate = NSPredicate(format: "lastPathComponent = '\(suggestedFilename)'")
            let filteredContents = (contents as NSArray).filteredArrayUsingPredicate(predicate)
            XCTAssertEqual(filteredContents.count, 1, "should have one file in Documents")
            
            if let file = filteredContents.first as? NSURL {
                XCTAssertEqual(
                    file.lastPathComponent ?? "",
                    "\(suggestedFilename)",
                    "filename should be \(suggestedFilename)"
                )
                
                if let data = NSData(contentsOfURL: file) {
                    XCTAssertGreaterThan(data.length, 0, "data length should be non-zero")
                } else {
                    XCTFail("data should exist for contents of URL")
                }
                
                do {
                    try fileManager.removeItemAtURL(file)
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
        
        let destination = Alamofire.Request.suggestedDownloadDestination(
            directory: searchPathDirectory,
            domain: searchPathDomain
        )
        let path = "/wikipedia/commons/6/69/NASA-HS201427a-HubbleUltraDeepField2014-20140603.jpg"
        let request: APIRequest<EmptyResponse,TronError> = tron.download(path: path, destination: destination)
        let expectation = expectationWithDescription("Download expectation")
        let alamofireRequest = request.perform(completion: { result in
            expectation.fulfill()
        })
        alamofireRequest?.progress { //_,_,_ in
            print("progress ",$0,$1,$2)
            alamofireRequest?.cancel()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
        
        guard let resumeData = alamofireRequest?.resumeData else {
            XCTFail("request should produce resume data")
            return
        }
        
        let continueDownloadRequest : APIRequest<EmptyResponse,TronError> = tron.download(path: path, destination: destination, resumingFromData : resumeData)
        let continueExpectation = expectationWithDescription("Continue download expectation")
        continueDownloadRequest.perform(completion: { result in
            continueExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(5, handler: nil)
        
        let fileManager = NSFileManager.defaultManager()
        let directory = fileManager.URLsForDirectory(searchPathDirectory, inDomains: self.searchPathDomain)[0]
        
        do {
            let contents = try fileManager.contentsOfDirectoryAtURL(
                directory,
                includingPropertiesForKeys: nil,
                options: .SkipsHiddenFiles
            )
            
            #if os(iOS) || os(tvOS)
                let suggestedFilename = "NASA-HS201427a-HubbleUltraDeepField2014-20140603.jpg"
            #elseif os(OSX)
                let suggestedFilename = "NASA-HS201427a-HubbleUltraDeepField2014-20140603.jpg"
            #endif
            
            let predicate = NSPredicate(format: "lastPathComponent = '\(suggestedFilename)'")
            let filteredContents = (contents as NSArray).filteredArrayUsingPredicate(predicate)
            XCTAssertEqual(filteredContents.count, 1, "should have one file in Documents")
            
            if let file = filteredContents.first as? NSURL {
                XCTAssertEqual(
                    file.lastPathComponent ?? "",
                    "\(suggestedFilename)",
                    "filename should be \(suggestedFilename)"
                )
                
                if let data = NSData(contentsOfURL: file) {
                    XCTAssertGreaterThan(data.length, 0, "data length should be non-zero")
                } else {
                    XCTFail("data should exist for contents of URL")
                }
                
                do {
                    try fileManager.removeItemAtURL(file)
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
