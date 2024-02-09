//
//  PingResponseTimeTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import XCTest

@testable import PingService

class PingResponseTimeTests: XCTestCase {

    var pingResponseTime: PingResponseTime!

    override func setUp() {
        super.setUp()
        pingResponseTime = PingResponseTime()
        pingResponseTime.windowSize = 3
    }

    override func tearDown() {
        super.tearDown()
        pingResponseTime = nil
    }

    func testAdd() {
        // When
        pingResponseTime.add(time: 1.0)

        // Then
        XCTAssertEqual(pingResponseTime.allResponseTime, [1.0])
        XCTAssertEqual(pingResponseTime.minTime, 1.0)
        XCTAssertEqual(pingResponseTime.maxTime, 1.0)
    }

    func testWindow() {
        // When
        pingResponseTime.add(time: 1.0)
        pingResponseTime.add(time: 2.0)
        pingResponseTime.add(time: 3.0)

        // Then
        XCTAssertEqual(pingResponseTime.window, [])
    }

    func testAverage() {
        // When
        [1.0, 2.0, 3.0, 1.0, 2.0, 3.0].forEach {
            pingResponseTime.add(time: $0)
        }

        // Then
        XCTAssertEqual(pingResponseTime.average, 2.0)
    }

    func testGetStatsResponseModel() {
        // When
        [1.0, 2.0, 3.0, 1.0, 2.0, 3.0].forEach {
            pingResponseTime.add(time: $0)
        }

        // Then
        let statsResponseModel = pingResponseTime.getStatsResponseModel()
        XCTAssertEqual(statsResponseModel.average, 2.0)
        XCTAssertEqual(statsResponseModel.min, 1.0)
        XCTAssertEqual(statsResponseModel.max, 3.0)
    }
}
