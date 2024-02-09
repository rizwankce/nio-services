//
//  PingChannelHandlerTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import XCTest
import NIO
import NIOHTTP1
@testable import PingService

final class PingChannelHandlerTests: XCTestCase {
    var channel: EmbeddedChannel!
    var handler: PingChannelHandler!
    var pingResponseTime: PingResponseTime!

    override func setUp() {
        super.setUp()
        // Given
        pingResponseTime = PingResponseTime()
        handler = PingChannelHandler(pingResponseTime: pingResponseTime)
        channel = EmbeddedChannel(handler: handler)
    }

    override func tearDown() {
        pingResponseTime = nil
        handler = nil
        channel = nil
        super.tearDown()
    }

    func _testPingRequest() throws {
        // When
        let eventLoop = EmbeddedEventLoop()
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/ping")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        // Then
        // Advance time by 5 seconds
        let advanceBy = pingResponseTime.allResponseTime.last! + 1000
        eventLoop.advanceTime(by: .milliseconds(Int64(advanceBy)))

        // Then
        if case .some(.head(let responseHead)) = try channel.readOutbound(as: HTTPServerResponsePart.self) {
            XCTAssertEqual(responseHead.status, .ok)
        } else {
            XCTFail("Expected response head")
        }
    }

    func testNonPingRequest() throws {
        // When
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/stats")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        // Then
        if case .some(.head(let responseHead)) = try channel.readOutbound(as: HTTPServerResponsePart.self) {
            XCTAssertEqual(responseHead.status, .notFound)
        } else {
            XCTFail("Expected response head")
        }
    }
}
