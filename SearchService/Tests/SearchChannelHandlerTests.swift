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
    var eventLoop: EmbeddedEventLoop!
    var channel: EmbeddedChannel!
    var handler: SearchChannelHandler!
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    let filePath = FileManager.default.temporaryDirectory.path(percentEncoded: true)
    var fileDownloadedAlready: Bool = false
    let dummyUUID = "00000000-0000-0000-0000-000000000001"

    override func setUp() {
        super.setUp()
        let polisDataProvider = MockPolisDataProvider(filePath: filePath)
        handler = SearchChannelHandler(polisDataProvider: polisDataProvider)
        eventLoop = EmbeddedEventLoop()
        channel = EmbeddedChannel(handler: handler, loop: eventLoop)
    }

    override func tearDown() {
        //XCTAssertNoThrow(try channel.finish())
        handler = nil
        channel = nil
        super.tearDown()
    }

    func verifyReponseHead(_ response: HTTPServerResponsePart?) {
        switch response {
            case .head(let head):
                XCTAssertEqual(head.status, .ok)
            default:
                XCTFail("Expected response head")
        }
    }

    func getResponseBody(_ response: HTTPServerResponsePart?) -> [String: Any] {
        switch response {
            case .body(let data):
                if case .byteBuffer(let buffer) = data {
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
                }
            default:
                XCTFail("Expected response body")
        }
        return [:]
    }

    func testGetNumberOfObservingFacilitiesRequest() throws {
        // When
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/api/numberOfObservingFacilities")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        // Then
        let head = try channel.readOutbound(as: HTTPServerResponsePart.self)
        verifyReponseHead(head)

        let body = try channel.readOutbound(as: HTTPServerResponsePart.self)
        let response = getResponseBody(body)
        XCTAssertNotNil(response["numberOfObservingFacilities"])
        XCTAssertEqual(10, response["numberOfObservingFacilities"] as! Int)

        let responseEnd = try channel.readOutbound(as: HTTPServerResponsePart.self)
        XCTAssertNotNil(responseEnd)
    }

    func testUpdateDateRequest() throws {
        // When
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/api/updateDate")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        // Then
        let head = try channel.readOutbound(as: HTTPServerResponsePart.self)
        verifyReponseHead(head)

        let body = try channel.readOutbound(as: HTTPServerResponsePart.self)
        let response = getResponseBody(body)
        XCTAssertNotNil(response["updatedDate"])
        XCTAssertEqual("2022-02-24T05:01:40Z", response["updatedDate"] as! String)

        let responseEnd = try channel.readOutbound(as: HTTPServerResponsePart.self)
        XCTAssertNotNil(responseEnd)
    }

    func testSearchRequest() throws {
        // When
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/api/search?name=dummy_search_name")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        // Then
        let head = try channel.readOutbound(as: HTTPServerResponsePart.self)
        verifyReponseHead(head)

        let body = try channel.readOutbound(as: HTTPServerResponsePart.self)
        let response = getResponseBody(body)
        let ids = response["uuids"] as? [String]
        XCTAssertNotNil(ids)
        XCTAssertEqual(ids?.count, 1)
        XCTAssertEqual(dummyUUID, ids?.first)

        let responseEnd = try channel.readOutbound(as: HTTPServerResponsePart.self)
        XCTAssertNotNil(responseEnd)
    }

    func testLocationRequest() throws {
        // When
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/api/location?uuid=\(dummyUUID)")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        // Then
        let head = try channel.readOutbound(as: HTTPServerResponsePart.self)
        verifyReponseHead(head)

        let body = try channel.readOutbound(as: HTTPServerResponsePart.self)
        let response = getResponseBody(body)
        let lat = response["latitude"] as? Double
        let long = response["longitude"] as? Double
        XCTAssertNotNil(response)
        XCTAssertNotNil(lat)
        XCTAssertNotNil(long)
        XCTAssertEqual(lat, 131.1)
        XCTAssertEqual(long, 10.1)

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
