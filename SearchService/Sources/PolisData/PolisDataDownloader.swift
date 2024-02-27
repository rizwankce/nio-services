//
//  PolisDataDownloader.swift
//
//
//  Created by Rizwan on 08/02/24.
//

import Foundation
import Logging
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOFileSystem
import NIOFoundationCompat
import swift_polis

/// An enumeration representing the possible errors that can occur during data downloading in the PolisDataDownloader.
public enum PolisDataDownloaderError: Error, Equatable {
    /// Error when the resource was not found.
    case resourceNotFound
    
    /// Error when the download failed.
    case failedToDownload
}

/**
 A class responsible for downloading Polis data.
 
 Use this class to download data from the Polis service.
 */
final class PolisDataDownloader {
    /// The logger for the `PolisDataDownloader`.
    let logger = Logger(label: "polis-data-downloader-nio")
    
    /// The URL of the POLIS remote .
    let polisUrl: String
    
    /// The file path to save the downloaded data.
    let filePath: String
    
    /// The event loop group for the `PolisDataDownloader`.
    let eventLoopGroup: MultiThreadedEventLoopGroup
    
    /// The event loop for the `PolisDataDownloader`.
    let eventLoop: EventLoop
    
    /// The remote resource finder to use POLIS resource location data from remote resource.
    let polisRemoteResource: PolisRemoteResourceFinder?
    
    /// The file resource finder to use POLIS resource location data from file resource.
    let polisFileResource: PolisFileResourceFinder?
    
    /// The version of the POLIS implementation.
    let polisVersion: String
    
    /// The data provider for Polis data.
    let polisDataProvider: PolisDataProvider
    
    /// Initializes a new `PolisDataDownloader` with the specified POLIS URL, file path, and event loop group.
    /// - Parameters:
    ///   - polisUrl: url of the POLIS remote.
    ///   - filePath: a file path to save the downloaded data.
    ///   - eventLoopGroup: an event loop group for the `PolisDataDownloader`.
    init(polisUrl: String, filePath: String, eventLoopGroup: MultiThreadedEventLoopGroup) {
        self.polisUrl = polisUrl
        self.filePath = filePath
        self.eventLoopGroup = eventLoopGroup
        self.eventLoop = eventLoopGroup.next()
        let version = PolisConstants.frameworkSupportedImplementation.last!.version
        self.polisVersion = version.description
        let polisImplementation = PolisImplementation(dataFormat: .json, apiSupport: .staticData, version: version)
        
        if let url = URL(string: polisUrl), let fileURL = URL(string: filePath) {
            self.polisRemoteResource = try? PolisRemoteResourceFinder(at: url, supportedImplementation: polisImplementation)
            self.polisFileResource = try? PolisFileResourceFinder(at: fileURL, supportedImplementation: polisImplementation)
        }
        else {
            self.polisRemoteResource = nil
            self.polisFileResource = nil
        }
        self.polisDataProvider = PolisDataProvider(filePath: filePath)
    }
    
    /// to download the data from the POLIS remote.
    /// - Returns: an event loop future that resolves to `Void` when the download is complete.
    func initiateAsyncDownload() -> EventLoopFuture<Void> {
        downloadConfigurationFile().flatMap {
            self.downloadDirectoryFile().flatMap {
                self.downloadObservingFacilitiesFile().flatMap {
                    self.downloadAllObservingFacilitiesFile()
                }
            }
        }
    }
    
    /// To download all the observing facilities file from the POLIS remote.
    /// - Returns: an event loop future that resolves to `Void` when the download is complete.
    func downloadAllObservingFacilitiesFile() -> EventLoopFuture<Void> {
        guard let polisRemoteResource = polisRemoteResource else {
            return eventLoop.makeFailedFuture(PolisDataDownloaderError.resourceNotFound)
        }
        
        return polisDataProvider.getAllUniqueIdentifiersFor(eventLoop: eventLoop).flatMap { ids -> EventLoopFuture<Void> in
            let createFilesFutures = ids.map { id -> EventLoopFuture<Void> in
                let url = polisRemoteResource.observingFacilityURL(observingFacilityID: id)
                let path = self.polisFileResource!.observingFacilityFile(observingFacilityID: id)
                return self.downloadPolisFile(from: url, to: path)
            }
            
            return EventLoopFuture.whenAllSucceed(createFilesFutures, on: self.eventLoop).flatMap {_ in
                let createLocationFilesFutures = ids.map { id -> EventLoopFuture<Void> in
                    return self.polisDataProvider.getLocationIDFor(facility: id, eventLoop: self.eventLoop)
                        .flatMap { locationID -> EventLoopFuture<Void> in
                            let url = polisRemoteResource.observingDataURL(withID: locationID, observingFacilityID: id)
                            let path = self.polisFileResource!.observingDataFile(withID: locationID, observingFacilityID: id)
                            return self.downloadPolisFile(from: url, to: path)
                        }
                }
                return EventLoopFuture.whenAllSucceed(createLocationFilesFutures, on: self.eventLoop).flatMap { _ -> EventLoopFuture<Void> in
                    self.eventLoop.makeSucceededVoidFuture()
                }
            }
        }
    }
    
    // To download the configuration file from the POLIS remote.
    /// Returns: an event loop future that resolves to `Void` when the download is complete.
    func downloadConfigurationFile() -> EventLoopFuture<Void> {
        guard let polisRemoteResource = polisRemoteResource else {
            return eventLoop.makeFailedFuture(PolisDataDownloaderError.resourceNotFound)
        }
        
        let url = polisRemoteResource.configurationURL()
        let path = polisFileResource!.configurationFile()
        return downloadPolisFile(from: url, to: path)
    }
    
    /// To download the directory file from the POLIS remote.
    /// Returns: an event loop future that resolves to `Void` when the download is complete.
    func downloadDirectoryFile() -> EventLoopFuture<Void> {
        guard let polisRemoteResource = polisRemoteResource else {
            return eventLoop.makeFailedFuture(PolisDataDownloaderError.resourceNotFound)
        }
        
        let url = polisRemoteResource.polisProviderDirectoryURL()
        let path = polisFileResource!.polisProviderDirectoryFile()
        return downloadPolisFile(from: url, to: path)
    }
    
    /// To download the observing facilities file from the POLIS remote.
    /// Returns: an event loop future that resolves to `Void` when the download is complete.
    func downloadObservingFacilitiesFile() -> EventLoopFuture<Void> {
        guard let polisRemoteResource = polisRemoteResource else {
            return eventLoop.makeFailedFuture(PolisDataDownloaderError.resourceNotFound)
        }
        
        let url = polisRemoteResource.observingFacilitiesDirectoryURL()
        let path = polisFileResource!.observingFacilitiesDirectoryFile()
        return downloadPolisFile(from: url, to: path)
    }
    
    /// To download the POLIS file from the POLIS remote.
    /// Returns: an event loop future that resolves to `Void` when the download is complete.
    func downloadPolisFile(from: String, to path: String) -> EventLoopFuture<Void> {
        return downloadJSON(urlString: from)
            .flatMap { buffer -> EventLoopFuture<Void> in
                self.saveJSONFile(path: path, byteBuffer: buffer)
            }
    }
    
    // To download the JSON from the POLIS remote.
    /// Returns: an event loop future that resolves to `Void` when the download is complete.
    func downloadJSON(urlString: String) -> EventLoopFuture<ByteBuffer> {
        guard let url = URL(string: urlString) else {
            return eventLoop.makeFailedFuture(URLError(.badURL))
        }

        return HTTPClient(eventLoopGroup: eventLoopGroup).get(url: url, eventLoop: eventLoop)
    }
    
    /// To create a directory at the specified path in non blocking way
    /// Returns: an event loop future that resolves to `Void` when the directory is created.
    func createDirectory(path: String) -> EventLoopFuture<Void> {
        logger.info("Creating directory at path: \(path)")
        let fileIO = NonBlockingFileIO(threadPool: .singleton)
        return fileIO.createDirectory(path: path, withIntermediateDirectories: true, mode: S_IRWXU, eventLoop: eventLoop)
    }
    
    /// To check if the directory exists at the specified path in non blocking way
    /// Returns: an event loop future that resolves to `Void` when the directory exists.
    func isDirectoryExists(path: String) -> EventLoopFuture<Void> {
        let fileIO = NonBlockingFileIO(threadPool: .singleton)
        return fileIO.openFile(path: path, eventLoop: eventLoop)
            .flatMap { result -> EventLoopFuture<Void> in
                do {
                    try result.0.close()
                    return self.eventLoop.makeSucceededVoidFuture()
                }
                catch {
                    return self.eventLoop.makeFailedFuture(error)
                }
            }
    }
    
    /// To save the JSON file at the specified path in non blocking way
    /// Returns:  an event loop future that resolves to `Void` when the file is saved.
    func saveJSONFile(path: String, byteBuffer: ByteBuffer) -> EventLoopFuture<Void> {
        logger.info("Saving JSON file at path: \(path)")
        let fileIO = NonBlockingFileIO(threadPool: .singleton)
        let directoryPath = URL(string: path)!.deletingLastPathComponent().absoluteString
        
        let writeFuture = isDirectoryExists(path: path)
            .flatMapError { _ -> EventLoopFuture<Void> in
                self.createDirectory(path: directoryPath)
            }
            .flatMap { _ -> EventLoopFuture<NIOFileHandle> in
                fileIO.openFile(path: path, mode: .write, flags: .allowFileCreation(), eventLoop: self.eventLoop)
            }
            .flatMap { fileHandle -> EventLoopFuture<Void> in
                fileIO.write(fileHandle: fileHandle, buffer: byteBuffer, eventLoop: self.eventLoop)
                    .always { _ in
                        do {
                            try fileHandle.close()
                        }
                        catch {
                            self.logger.error("error :\(error)")
                        }
                    }
            }
        return writeFuture
    }
}
