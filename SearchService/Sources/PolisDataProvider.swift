//
//  PolisDataProvider.swift
//
//
//  Created by Rizwan on 07/02/24.
//

import Foundation
import Logging
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOFileSystem
import NIOFoundationCompat
import swift_polis

/// Errors that can occur in the `PolisDataProvider`.
public enum PolisDataProviderError: Error, Equatable {
    /// The resource was not found.
    case resourceNotFound
    
    /// The data could not be decoded.
    case decodeFailure
    
    /// The observing facility is missing.
    case missingObservingFacility
}

/// A data provider for Polis.
final class PolisDataProvider {
    /// The logger for the `PolisDataProvider`.
    let logger = Logger(label: "polis-data-provider-nio")
    
    /// The Polis file resource finder.
    var poliseFileResource: PolisFileResourceFinder?
    
    /// The file path for POLIS data.
    let filePath: String
    
    /// Initializes the `PolisDataProvider` with the given file path.
    /// - Parameter filePath: The path to the POLIS file.
    init(filePath: String) {
        self.poliseFileResource = nil
        self.filePath = filePath
        let url = URL(filePath: filePath)
        let version = PolisConstants.frameworkSupportedImplementation.last!.version
        let polisImplementation = PolisImplementation(dataFormat: .json, apiSupport: .staticData, version: version)
        poliseFileResource = try? PolisFileResourceFinder(at: url, supportedImplementation: polisImplementation)
    }
    
    /// Retrieves the updated at information from the POLIS Directory.
    /// - Parameter eventLoop: The event loop to use.
    /// - Returns: An `EventLoopFuture` containing the updated at information.
    func getUpdatedAt(eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        guard let resource = poliseFileResource else {
            return eventLoop.makeFailedFuture(PolisDataProviderError.resourceNotFound)
        }
        let buffer = getDataFromFile(resource.configurationFile(), eventLoop)
        return buffer.flatMap { buffer -> EventLoopFuture<ByteBuffer> in
            do {
                guard let config = try buffer.getJSONDecodable(
                    PolisDirectory.ProviderDirectoryEntry.self,
                    decoder: PolisJSONDecoder(),
                    at: buffer.readerIndex,
                    length: buffer.readableBytes
                ) else {
                    return eventLoop.makeFailedFuture(PolisDataProviderError.decodeFailure)
                }
                let jsonResponse = [
                    "updatedDate" : config.lastUpdate
                ]
                var responseBuffer = ByteBufferAllocator().buffer(capacity: 1024)
                try PolisJSONEncoder().encode(jsonResponse, into: &responseBuffer)
                return eventLoop.makeSucceededFuture(responseBuffer)
            }
            catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    /// Retrieves the number of observing facilities.
    /// - Parameter eventLoop: The event loop to use.
    /// - Returns: An `EventLoopFuture` containing the number of observing facilities.
    func getNumberOfObservingFacilities(eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        guard let resource = poliseFileResource else {
            return eventLoop.makeFailedFuture(PolisDataProviderError.resourceNotFound)
        }
        let buffer = getDataFromFile(resource.observingFacilitiesDirectoryFile(), eventLoop)
        return buffer.flatMap { buffer -> EventLoopFuture<ByteBuffer> in
            do {
                guard let config = try buffer.getJSONDecodable(
                    PolisObservingFacilityDirectory.self,
                    decoder: PolisJSONDecoder(),
                    at: buffer.readerIndex,
                    length: buffer.readableBytes
                ) else {
                    return eventLoop.makeFailedFuture(PolisDataProviderError.decodeFailure)
                }
                let jsonResponse = [
                    "numberOfObservingFacilities" : config.observingFacilityReferences.count
                ]
                var responseBuffer = ByteBufferAllocator().buffer(capacity: 1024)
                try PolisJSONEncoder().encode(jsonResponse, into: &responseBuffer)
                return eventLoop.makeSucceededFuture(responseBuffer)
            }
            catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    /// Retrieves the unique identifiers for a facility.
    /// - Parameters:
    ///   - name: The name of the facility.
    ///   - eventLoop: The event loop to use.
    /// - Returns: An `EventLoopFuture` containing the unique identifiers.
    func getUniqueIdentifiersFor(faciltiy name: String, eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        let future = getAllUniqueIdentifiersFor(faciltiy: name, eventLoop: eventLoop)
        return future.flatMap { ids -> EventLoopFuture<ByteBuffer> in
            let jsonResponse = [ "uuids" : [ ids ]]
            var responseBuffer = ByteBufferAllocator().buffer(capacity: 1024)
            do {
                try PolisJSONEncoder().encode(jsonResponse, into: &responseBuffer)
                return eventLoop.makeSucceededFuture(responseBuffer)
            }
            catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    /// Retrieves all unique identifiers for a facility.
    /// - Parameters:
    ///   - name: The name of the facility. If `nil`, retrieves all unique identifiers.
    ///   - eventLoop: The event loop to use.
    /// - Returns: An `EventLoopFuture` containing the unique identifiers.
    func getAllUniqueIdentifiersFor(faciltiy name: String? = nil, eventLoop: EventLoop) -> EventLoopFuture<[UUID]> {
        guard let resource = poliseFileResource else {
            return eventLoop.makeFailedFuture(PolisDataProviderError.resourceNotFound)
        }
        let buffer = getDataFromFile(resource.observingFacilitiesDirectoryFile(), eventLoop)
        return buffer.flatMap { buffer -> EventLoopFuture<[UUID]> in
            do {
                guard let config = try buffer.getJSONDecodable(
                    PolisObservingFacilityDirectory.self,
                    decoder: PolisJSONDecoder(),
                    at: buffer.readerIndex,
                    length: buffer.readableBytes
                ) else {
                    return eventLoop.makeFailedFuture(PolisDataProviderError.decodeFailure)
                }
                if let name = name {
                    let filteredIds = config.observingFacilityReferences
                        .filter { $0.identity.name.contains(name) }
                        .map { $0.id }
                    return eventLoop.makeSucceededFuture(filteredIds)
                }
                else {
                    let ids = config.observingFacilityReferences.map { $0.id }
                    return eventLoop.makeSucceededFuture(ids)
                }
            }
            catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    /// Retrieves the location for a unique identifier.
    /// - Parameters:
    ///   - identifier: The unique identifier.
    ///   - eventLoop: The event loop to use.
    /// - Returns: An `EventLoopFuture` containing the location information.
    func getLocationFor(uniqueIdentifier identifier: UUID, eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        guard let resource = poliseFileResource else {
            return eventLoop.makeFailedFuture(PolisDataProviderError.resourceNotFound)
        }
        let locationIDFuture = getLocationIDFor(facility: identifier, eventLoop: eventLoop)
        
        return locationIDFuture.flatMap { UUID -> EventLoopFuture<ByteBuffer> in
            let buffer = self.getDataFromFile(resource.observingDataFile(withID: UUID, observingFacilityID: identifier), eventLoop)
            return buffer.flatMap { buffer -> EventLoopFuture<ByteBuffer> in
                do {
                    guard let config = try buffer.getJSONDecodable(
                        PolisObservingFacilityLocation.self,
                        decoder: PolisJSONDecoder(),
                        at: buffer.readerIndex,
                        length: buffer.readableBytes
                    ) else {
                        return eventLoop.makeFailedFuture(PolisDataProviderError.decodeFailure)
                    }
                    guard let longitude = config.eastLongitude?.doubleValue(),
                          let latitude = config.latitude?.doubleValue() else {
                        return eventLoop.makeFailedFuture(PolisDataProviderError.decodeFailure)
                    }
                    
                    let jsonResponse = [
                        "longitude" : longitude,
                        "latitude" : latitude
                    ]
                    var responseBuffer = ByteBufferAllocator().buffer(capacity: 1024)
                    try PolisJSONEncoder().encode(jsonResponse, into: &responseBuffer)
                    return eventLoop.makeSucceededFuture(responseBuffer)
                }
                catch {
                    return eventLoop.makeFailedFuture(error)
                }
            }
        }
    }
    
    /// Retrieves the location ID for a facility.
    /// - Parameters:
    ///   - identifier: The unique identifier of the facility.
    ///   - eventLoop: The event loop to use.
    /// - Returns: An `EventLoopFuture` containing the location ID.
    func getLocationIDFor(facility identifier: UUID, eventLoop: EventLoop) -> EventLoopFuture<UUID> {
        guard let resource = poliseFileResource else {
            return eventLoop.makeFailedFuture(PolisDataProviderError.resourceNotFound)
        }
        let buffer = getDataFromFile(resource.observingFacilityFile(observingFacilityID: identifier), eventLoop)
        return buffer.flatMap { buffer -> EventLoopFuture<UUID> in
            do {
                guard let config = try buffer.getJSONDecodable(
                    PolisObservingFacility.self,
                    decoder: PolisJSONDecoder(),
                    at: buffer.readerIndex,
                    length: buffer.readableBytes
                ) else {
                    return eventLoop.makeFailedFuture(PolisDataProviderError.decodeFailure)
                }
                guard let locationID = config.facilityLocationID else {
                    return eventLoop.makeFailedFuture(PolisDataProviderError.missingObservingFacility)
                }
                return eventLoop.makeSucceededFuture(locationID)
            }
            catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    /// Retrieves data from a file.
    /// - Parameters:
    ///   - filePath: The path to the file.
    ///   - eventLoop: The event loop to use.
    /// - Returns: An `EventLoopFuture` containing the data.
    func getDataFromFile(_ filePath: String, _ eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        let eventLoop = eventLoop
        let fileIO = NonBlockingFileIO(threadPool: .singleton)
        return fileIO.openFile(path: filePath, eventLoop: eventLoop)
            .flatMap { (fileHandle, region) in
                fileIO.read(fileRegion: region, allocator: ByteBufferAllocator(), eventLoop: eventLoop)
                    .map { buffer in
                        return buffer
                    }
                    .flatMapError { error in
                        eventLoop.makeFailedFuture(error)
                    }
                    .always {_ in
                        try? fileHandle.close()
                    }
            }
            .flatMapError { error in
                eventLoop.makeFailedFuture(error)
            }
    }
}
