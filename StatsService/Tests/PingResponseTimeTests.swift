//
//  StatsDataProcessorTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import XCTest
@testable import StatsService

final class PingResponseTimeTests: XCTestCase {
    var pingResponseTime: PingResponseTime!
    
    override func setUp() {
        super.setUp()
        // Given
        pingResponseTime = PingResponseTime()
    }
    
    override func tearDown() {
        pingResponseTime = nil
        super.tearDown()
    }
    
    func testAddTime() {
        // When
        pingResponseTime.add(time: 1.0)
        pingResponseTime.add(time: 2.0)
        pingResponseTime.add(time: 3.0)
        
        // Then
        XCTAssertEqual(pingResponseTime.count, 3)
        XCTAssertEqual(pingResponseTime.totalTime, 6.0)
        XCTAssertEqual(pingResponseTime.minTime, 1.0)
        XCTAssertEqual(pingResponseTime.maxTime, 3.0)
    }
    
    func testAverageTime() {
        // When
        pingResponseTime.add(time: 1.0)
        pingResponseTime.add(time: 2.0)
        pingResponseTime.add(time: 3.0)
        
        // Then
        XCTAssertEqual(pingResponseTime.averageTime, 2.0)
    }
}
