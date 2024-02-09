//
//  PingServiceTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import XCTest
import ArgumentParser
import NIO

@testable import PingService

final class PingServiceTests: XCTestCase {
    var pingService: PingService!
    
    var clientBootstrap: ClientBootstrap {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        return ClientBootstrap(group: group)
    }
    
    override func setUp() {
        super.setUp()
        pingService = PingService()
    }
    
    override func tearDown() {
        pingService = nil
        super.tearDown()
    }
    
    func testDefaultValues() throws {
        // Given
        let args = ["5","/path/temp/"]
        
        // When
        let parsedPingService = try PingService.parse(args)
        
        // Then
        XCTAssertFalse(parsedPingService.verbose)
        XCTAssertNil(parsedPingService.host)
        XCTAssertNil(parsedPingService.port)
        XCTAssertEqual(parsedPingService.windowSize, 5)
        XCTAssertEqual(parsedPingService.filePath, "/path/temp/")
    }
    
    func testParseArgumentsAndOptions() throws {
        // Given
        let args = ["--verbose", "-h", "localhost", "-p", "8080", "1000", "/path/tmp/"]
        
        // When
        let parsedPingService = try PingService.parse(args)
        
        // Then
        XCTAssertTrue(parsedPingService.verbose)
        XCTAssertEqual(parsedPingService.host, "localhost")
        XCTAssertEqual(parsedPingService.port, 8080)
        XCTAssertEqual(parsedPingService.windowSize, 1000)
        XCTAssertEqual(parsedPingService.filePath, "/path/tmp/")
    }
}

