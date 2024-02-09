//
//  StatsChannelHandlerTests.swift
//
//
//  Created by Rizwan on 09/02/24.
//

import XCTest
import NIO
import NIOHTTP1
import NIOFoundationCompat

@testable import StatsService

final class StatsChannelHandlerTests: XCTestCase {
    var channel: EmbeddedChannel!
    var handler: StatesChannelHandler!
    var pingResponseTime: PingResponseTime!

    override func setUp() {
        super.setUp()
        // Given
        pingResponseTime = PingResponseTime()
        handler = StatesChannelHandler(pingResponseTime: pingResponseTime)
        channel = EmbeddedChannel(handler: handler)
    }

    override func tearDown() {
        pingResponseTime = nil
        handler = nil
        channel = nil
        super.tearDown()
    }

    func testChannelReadForStats() throws {
        // When
        pingResponseTime.add(time: 1.0)
        pingResponseTime.add(time: 2.0)
        pingResponseTime.add(time: 3.0)
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/stats")
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
                let model = try JSONDecoder().decode(StatsResponseModel.self, from: buffer)
                print(model)
                XCTAssertTrue(model.uptime != 0.0)
                XCTAssertEqual(model.responseTime.average, 2.0)
                XCTAssertEqual(model.responseTime.min, 1.0)
                XCTAssertEqual(model.responseTime.max, 3.0)
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
