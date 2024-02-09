//
//  SearchChannelHandlerTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import XCTest
import NIO
import NIOHTTP1
import swift_polis

@testable import SearchService

final class SearchChannelHandlerTests: XCTestCase {
    var channel: EmbeddedChannel!
    var handler: SearchChannelHandler!
    let filePath = FileManager.default.temporaryDirectory.path(percentEncoded: true)

    override func setUp() {
        super.setUp()
        let polisDataProvider = PolisDataProvider(filePath: filePath)
        handler = SearchChannelHandler(polisDataProvider: polisDataProvider)
        channel = EmbeddedChannel(handler: handler)
    }

    override func tearDown() {
        //XCTAssertNoThrow(try channel.finish())
        handler = nil
        channel = nil
        super.tearDown()
    }

    func _testSearchRequest() throws {
        // When
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            do {
                try eventLoopGroup.syncShutdownGracefully()
            }
            catch { }
        }
        let downloader = PolisDataDownloader(
            polisUrl: PolisConstants.testBigBangPolisDomain,
            filePath: filePath,
            eventLoopGroup: eventLoopGroup
        )
        try downloader.initiateAsyncDownload().wait()

        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/api/numberOfObservingFacilities")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        // Then
        if case .some(.head(let responseHead)) = try channel.readOutbound(as: HTTPServerResponsePart.self) {
            XCTAssertEqual(responseHead.status, .ok)
        } else {
            XCTFail("Expected response head")
        }

        let responseBody = try channel.readOutbound(as: HTTPServerResponsePart.self)

        if case .some(.body(let data)) = responseBody {
            if case .byteBuffer(let buffer) = data {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: buffer, options: [])
                    if let response = jsonObject as? [String: Any] {
                        XCTAssertNotNil(response["updateDate"])
                    } else {
                        XCTFail("Expected JSON array of search results")
                    }
                } catch {
                    XCTFail("Failed to decode JSON: \(error)")
                }
            }
        } else {
            XCTFail("Expected response body")
        }

        let responseEnd = try channel.readOutbound(as: HTTPServerResponsePart.self)
        XCTAssertNotNil(responseEnd)
    }

    func testChannelReadForStatsNotFoundError() throws {
        // When
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/ping")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        // Then
        if case .some(.head(let responseHead)) = try channel.readOutbound(as: HTTPServerResponsePart.self) {
            XCTAssertEqual(responseHead.status, .notFound)
        } else {
            XCTFail("Expected response head")
        }
    }
}
