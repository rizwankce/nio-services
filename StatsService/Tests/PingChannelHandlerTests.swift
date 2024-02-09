//
//  PingChannelHandlerTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import XCTest
import NIO
import NIOHTTP1
@testable import StatsService

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
        XCTAssertNoThrow(try channel.finish())
        pingResponseTime = nil
        handler = nil
        channel = nil
        super.tearDown()
    }

    func testChannelRead() throws {
        // When
        channel.pipeline.fireChannelActive()
        let responseHead = HTTPResponseHead(version: .http1_1, status: .ok)
        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.head(responseHead)))

        // Then
        print(try channel.readOutbound(as: HTTPClientRequestPart.self))
        XCTAssertEqual(pingResponseTime.count, 1)
    }
}

