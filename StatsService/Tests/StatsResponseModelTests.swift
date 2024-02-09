//
//  StatsResponseModelTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import XCTest

@testable import StatsService

final class StatsResponseModelTests: XCTestCase {
    var statsResponseModel: StatsResponseModel!
    
    override func setUp() {
        super.setUp()
        // Given
        let responseTime = ResponseTime(average: 1.0, min: 0.5, max: 1.5)
        statsResponseModel = StatsResponseModel(uptime: 100.0, responseTime: responseTime)
    }

    override func tearDown() {
        statsResponseModel = nil
        super.tearDown()
    }

    func testStatsResponseModel() {
        // When
        let uptime = statsResponseModel.uptime
        let responseTime = statsResponseModel.responseTime

        // Then
        XCTAssertEqual(uptime, 100.0)
        XCTAssertEqual(responseTime.average, 1.0)
        XCTAssertEqual(responseTime.min, 0.5)
        XCTAssertEqual(responseTime.max, 1.5)
    }
}
