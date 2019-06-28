//
//  URLBuilderTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 28.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON

class URLBuilderTestCase: XCTestCase {

    let tron = TRON(baseURL: "https://github.com")

    func testURLBuildableAppendsPathComponent() {
        XCTAssertEqual(tron.urlBuilder.url(forPath: "foo").absoluteString, "https://github.com/foo")
        XCTAssertEqual(tron.urlBuilder.url(forPath: "/bar").absoluteString, "https://github.com/bar")
    }
    
    func testAppendingPathComponentBuilder() {
        let builder = URLBuilder(baseURL: "https://www.example.com")
        XCTAssertEqual(builder.url(forPath: "foo").absoluteString, "https://www.example.com/foo")
        XCTAssertEqual(builder.url(forPath: "foo/bar").absoluteString, "https://www.example.com/foo/bar")
        
        let pathBuilder = URLBuilder(baseURL: "https://www.example.com/api")
        XCTAssertEqual(pathBuilder.url(forPath: "foo").absoluteString, "https://www.example.com/api/foo")
        XCTAssertEqual(pathBuilder.url(forPath: "foo/bar").absoluteString, "https://www.example.com/api/foo/bar")
    }
    
    func testRelativeToBaseURLBuilder() {
        let builder = URLBuilder(baseURL: "https://www.example.com/", behavior: .relativeToBaseURL)
        XCTAssertEqual(builder.url(forPath: "bar").absoluteString, "https://www.example.com/bar")
        XCTAssertEqual(builder.url(forPath: "foo/bar").absoluteString, "https://www.example.com/foo/bar")
        
        let pathBuilder = URLBuilder(baseURL: "https://www.example.com/api/", behavior: .relativeToBaseURL)
        XCTAssertEqual(pathBuilder.url(forPath: "foo").absoluteString, "https://www.example.com/api/foo")
        XCTAssertEqual(pathBuilder.url(forPath: "foo/bar").absoluteString, "https://www.example.com/api/foo/bar")
        
        XCTAssertEqual(pathBuilder.url(forPath: "https://www.example.com/foo").absoluteString, "https://www.example.com/foo")
    }
    
    func testCustomURLBuilder() {
        let builder = URLBuilder(baseURL: "https://www.example.com", behavior: .custom({ baseURL, path in
            return URL(string: baseURL + "/api" + path) ?? URL(fileURLWithPath: "")
        }))
        
        XCTAssertEqual(builder.url(forPath: "/bar").absoluteString, "https://www.example.com/api/bar")
    }
}
