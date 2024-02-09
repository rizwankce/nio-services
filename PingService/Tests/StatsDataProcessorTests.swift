//
//  StatsDataProcessorTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import Foundation
import XCTest
import NIOCore
import NIOFileSystem
import NIOCore
import NIOPosix

@testable import PingService

final class StatsDataProcessorTests: XCTestCase {
    var statsDataProcessor: StatsDataProcessor!
    var eventLoop: EventLoop!
    
    var temporyDirectoryPath: String {
        FileManager.default.temporaryDirectory.path(percentEncoded: true)
    }
    
    override func setUp() {
        super.setUp()
        
        eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        statsDataProcessor = StatsDataProcessor(filePath: temporyDirectoryPath, eventLoop: eventLoop)
    }
    
    override func tearDown() {
        super.tearDown()
        Task {
            try await eventLoop.shutdownGracefully()
        }
    }
    
    func testInit() {
        // Given
        let filePath = temporyDirectoryPath
        
        // When
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        let statsDataProcessor = StatsDataProcessor(filePath: filePath, eventLoop: eventLoop)
        
        // Then
        XCTAssertNotNil(statsDataProcessor)
    }
    
    func testExport() {
        // Given
        let pingResponseTime = PingResponseTime()
        
        // When
        pingResponseTime.add(time: 100)
        pingResponseTime.add(time: 1000)
        pingResponseTime.add(time: 1010)
        let statsResponseModel = pingResponseTime.getStatsResponseModel()
        
        let future = statsDataProcessor.export(statsResponseModel)
        let expectation = self.expectation(description: "export should complete successfully")
        
        // Then
        future.whenComplete { result in
            switch result {
                case .success:
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Error exporting statistics data: \(error)")
            }
        }
        waitForExpectations(timeout:  5)
    }
    
    func testPurgeOldDataIfNeededWithoutOldData() {
        // Given
        let future = statsDataProcessor.purgeOldDataIfNeeded()
        
        // Then
        let expectation = self.expectation(description: "purge data should complete successfully")
        future.whenComplete { result in
            switch result {
                case .success:
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Error purging old data: \(error)")
            }
        }
        
        waitForExpectations(timeout: 5)
    }
}

