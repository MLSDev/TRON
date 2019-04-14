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
    
}
