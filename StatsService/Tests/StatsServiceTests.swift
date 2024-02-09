//
//  StatsServiceTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import XCTest
import ArgumentParser
import NIO

@testable import StatsService

final class StatsServiceTests: XCTestCase {
    var statsService: StatsService!

    override func setUp() {
        super.setUp()
        statsService = StatsService()
    }

    override func tearDown() {
        statsService = nil
        super.tearDown()
    }

    func testDefaultValues() throws {
        // Given
        let args = ["1000"]

        // When
        let parsedStatsService = try StatsService.parse(args)

        // Then
        XCTAssertFalse(parsedStatsService.verbose)
        XCTAssertNil(parsedStatsService.host)
        XCTAssertNil(parsedStatsService.port)
        XCTAssertEqual(parsedStatsService.delay, 1000)
    }

    func testParseArgumentsAndOptions() throws {
        // Given
        let args = [
            "--verbose",
            "-h", "localhost",
            "-p", "2346",
            "--ping-host", "localhost",
            "--ping-port", "2345",
            "1000"
        ]

        // When
        let parsedStatsService = try StatsService.parse(args)

        // Then
        XCTAssertTrue(parsedStatsService.verbose)
        XCTAssertEqual(parsedStatsService.host, "localhost")
        XCTAssertEqual(parsedStatsService.port, 2346)
        XCTAssertEqual(parsedStatsService.pingHost, "localhost")
        XCTAssertEqual(parsedStatsService.pingPort, 2345)
        XCTAssertEqual(parsedStatsService.delay, 1000)
    }
}

