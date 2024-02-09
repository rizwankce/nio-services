//
//  File.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import Foundation
import XCTest
import NIO
import NIOFoundationCompat
import swift_polis

@testable import SearchService

final class PolisDataProviderTests: XCTestCase {
    var eventLoop: EmbeddedEventLoop!
    var polisDataProvider: PolisDataProvider!
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    let filePath = FileManager.default.temporaryDirectory.path(percentEncoded: true)
    var fileDownloadedAlready: Bool = false

    override func setUp() {
        super.setUp()
        eventLoop = EmbeddedEventLoop()
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        polisDataProvider = PolisDataProvider(filePath: filePath)
    }

    override func tearDown() {
        eventLoop = nil
        polisDataProvider = nil
        do {
            try eventLoopGroup.syncShutdownGracefully()
        }
        catch {
            print(error)
        }
        super.tearDown()
    }

    func downloadData() throws {
        guard !fileDownloadedAlready else { return }
        let downloader = PolisDataDownloader(
            polisUrl: PolisConstants.testBigBangPolisDomain,
            filePath: filePath,
            eventLoopGroup: eventLoopGroup)
        try downloader.initiateAsyncDownload().wait()
    }


    func getResponseJSON(from buffer: ByteBuffer) -> [String: Any] {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: buffer, options: [])
            if let response = jsonObject as? [String: Any] {
                return response
            } else {
                XCTFail("Expected JSON array of search results")
            }
        } catch {
            XCTFail("Failed to decode JSON: \(error)")
        }
        return [:]
    }

    func testGetUpdatedAt() throws {
        // Given
        try downloadData()

        // When
        let updatedAtFuture = polisDataProvider.getUpdatedAt(eventLoop: eventLoop)
        
        // Then
        updatedAtFuture.whenComplete { result in
            switch result {
                case .success(let success):
                    let response = self.getResponseJSON(from: success)
                    XCTAssertNotNil(response["updatedDate"])
                case .failure(let failure):
                    XCTFail("data provider failed : \(failure)")
            }
        }
    }

    func testGetNumberOfObservingFacilities() throws {
        // Given
        try downloadData()

        // When
        let updatedAtFuture = polisDataProvider.getNumberOfObservingFacilities(eventLoop: eventLoop)

        // Then
        updatedAtFuture.whenComplete { result in
            switch result {
                case .success(let success):
                    let response = self.getResponseJSON(from: success)
                    XCTAssertNotNil(response["numberOfObservingFacilities"])
                case .failure(let failure):
                    XCTFail("data provider failed : \(failure)")
            }
        }
    }

    func testGetUniqueIdentifiersForFacility() throws {
        // Given
        try downloadData()

        // When
        let updatedAtFuture = polisDataProvider.getUniqueIdentifiersFor(faciltiy: "Observatory", eventLoop: eventLoop)

        // Then
        updatedAtFuture.whenComplete { result in
            switch result {
                case .success(let success):
                    let response = self.getResponseJSON(from: success)
                    XCTAssertNotNil(response["uuids"])
                case .failure(let failure):
                    XCTFail("data provider failed : \(failure)")
            }
        }
    }

    func testGetLocationForID() throws {
        // Given
        try downloadData()
        let ids = try polisDataProvider.getAllUniqueIdentifiersFor(faciltiy: "Observatory", eventLoop: eventLoop).wait()

        // When
        let updatedAtFuture = polisDataProvider.getLocationFor(uniqueIdentifier: ids.first! , eventLoop: eventLoop)

        // Then
        updatedAtFuture.whenComplete { result in
            switch result {
                case .success(let success):
                    let response = self.getResponseJSON(from: success)
                    XCTAssertNotNil(response["latitude"])
                    XCTAssertNotNil(response["longitude"])
                case .failure(let failure):
                    XCTFail("data provider failed : \(failure)")
            }
        }
    }
}
