//
//  URLBuilderTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 28.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

class URLBuilderTestCase: XCTestCase {
    
    let tron = TRON(baseURL: "https://github.com")
    
    func testURLBuildableAppendsPathComponent() {
        XCTAssertEqual(tron.urlBuilder.url(forPath: "foo").absoluteString, "https://github.com/foo")
        XCTAssertEqual(tron.urlBuilder.url(forPath: "/bar").absoluteString, "https://github.com/bar")
    }
    
    func testURLBuildableAcceptsAbsolutePath() {
        XCTAssertEqual(tron.urlBuilder.url(forPath: "https://www.example.com/foo").absoluteString, "https://www.example.com/foo")
    }
    
}
