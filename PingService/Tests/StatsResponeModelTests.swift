//
//  StatsResponseModelTests.swift
//  
//
//  Created by Rizwan on 09/02/24.
//

import Foundation
import XCTest

@testable import PingService

class StatsResponseModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testStatsResponseModel() {
        // Given
        let statsResponseModel = StatsResponseModel(average: 10.0, min: 5.0, max: 15.0)
        
        // Then
        XCTAssertEqual(statsResponseModel.average, 10.0)
        XCTAssertEqual(statsResponseModel.min, 5.0)
        XCTAssertEqual(statsResponseModel.max, 15.0)
    }
    
}
