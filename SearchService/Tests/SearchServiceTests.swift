//
//  SearchServiceTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import XCTest
import ArgumentParser
import NIO

@testable import SearchService

final class SearchServiceTests: XCTestCase {
    var searchService: SearchService!

    override func setUp() {
        super.setUp()
        searchService = SearchService()
    }

    override func tearDown() {
        searchService = nil
        super.tearDown()
    }

    func testDefaultValues() throws {
        // Given
        let args = [
            "--polis-remote-data-file-path", "/path/tmp/"
        ]

        // When
        let parsedSearchService = try SearchService.parse(args)

        // Then
        XCTAssertFalse(parsedSearchService.verbose)
        XCTAssertNil(parsedSearchService.host)
        XCTAssertNil(parsedSearchService.port)
        XCTAssertNil(parsedSearchService.url)
        XCTAssertEqual(parsedSearchService.polisRemoteDataFilePath, "/path/tmp/")
    }

    func testParseArgumentsAndOptions() throws {
        // Given
        let args = [
            "--verbose",
            "-h", "localhost",
            "-p", "2347",
            "-u", "https://domain.com",
            "--polis-remote-data-file-path", "/path/tmp/"
        ]

        // When
        let parsedSearchService = try SearchService.parse(args)

        // Then
        XCTAssertTrue(parsedSearchService.verbose)
        XCTAssertEqual(parsedSearchService.host, "localhost")
        XCTAssertEqual(parsedSearchService.port, 2347)
        XCTAssertEqual(parsedSearchService.url, "https://domain.com")
        XCTAssertEqual(parsedSearchService.polisRemoteDataFilePath, "/path/tmp/")
    }
}

