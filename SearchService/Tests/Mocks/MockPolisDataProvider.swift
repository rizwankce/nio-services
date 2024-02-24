//
//  MockPolisDataProvider.swift
//  
//
//  Created by Rizwan on 24/02/24.
//

import Foundation
import NIO
import NIOHTTP1
import swift_polis

@testable import SearchService

public class MockPolisDataProvider: PolisDataProvider {
    public override func getNumberOfObservingFacilities(eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        do {
            let jsonResponse = [
                "numberOfObservingFacilities" : 10
            ]
            var responseBuffer = ByteBufferAllocator().buffer(capacity: 1024)
            try PolisJSONEncoder().encode(jsonResponse, into: &responseBuffer)
            return eventLoop.makeSucceededFuture(responseBuffer)
        }
        catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    public override func getUpdatedAt(eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        do {
            let jsonResponse = [
                "updatedDate" : Date(timeIntervalSince1970: 1645678900)
            ]
            var responseBuffer = ByteBufferAllocator().buffer(capacity: 1024)
            try PolisJSONEncoder().encode(jsonResponse, into: &responseBuffer)
            return eventLoop.makeSucceededFuture(responseBuffer)
        }
        catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    public override func getAllUniqueIdentifiersFor(faciltiy name: String? = nil, eventLoop: EventLoop) -> EventLoopFuture<[UUID]> {
        if name == "dummy_search_name" {
            return eventLoop.makeSucceededFuture([
                UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
            ])
        }
        return eventLoop.makeFailedFuture(PolisDataProviderError.missingObservingFacility)
    }

    public override func getLocationIDFor(facility identifier: UUID, eventLoop: EventLoop) -> EventLoopFuture<UUID> {
        if identifier.uuidString == "00000000-0000-0000-0000-000000000001" {
            return eventLoop.makeSucceededFuture(
                UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
            )
        }
        return eventLoop.makeFailedFuture(PolisDataProviderError.missingObservingFacility)
    }

    public override func getLocationFor(uniqueIdentifier identifier: UUID, eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        if identifier.uuidString == "00000000-0000-0000-0000-000000000001" {
            do {
                let jsonResponse = [
                    "longitude" : 10.1,
                    "latitude" : 131.1
                ]
                var responseBuffer = ByteBufferAllocator().buffer(capacity: 1024)
                try PolisJSONEncoder().encode(jsonResponse, into: &responseBuffer)
                return eventLoop.makeSucceededFuture(responseBuffer)
            }
            catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
        return eventLoop.makeFailedFuture(PolisDataProviderError.missingObservingFacility)
    }
}
