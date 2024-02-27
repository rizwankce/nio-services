//
//  JSONExporter.swift
//
//
//  Created by Rizwan on 06/02/24.
//

import Foundation
import Logging
import NIOFileSystem
import NIOCore
import NIOPosix

/// A class that processes and exports statistics data.
public class StatsDataProcessor {
    /// The logger used for logging events.
    let logger = Logger(label: "stats-data-processor-nio")
    
    /// The file path where the statistics data will be exported.
    private let filePath: String
    
    private let eventLoop: EventLoop
    
    /// The file system used for file operations.
    private let fileSystem: FileSystem = FileSystem.shared
    
    /// Initializes a `StatsDataProcessor` instance with the given file path.
    /// - Parameter filePath: The file path where the statistics data will be exported.
    public init(filePath: String, eventLoop: EventLoop) {
        self.filePath = filePath
        self.eventLoop = eventLoop
    }
    
    /// Exports the given statistics response model to a JSON file.
    /// - Parameter statsResponseModel: An `StatsResponseModel` instance to be exported.
    /// - Returns: An event loop future that resolves to `Void` when the statistics data is exported.
    public func export(_ statsResponseModel: StatsResponseModel) -> EventLoopFuture<Void> {
        let directoryPath = getDirectoryPath()
        let timestamp = getTimestamp()
        
        let path = filePath + directoryPath + "/\(timestamp).json"
        let fileIO = NonBlockingFileIO(threadPool: .singleton)
        
        logger.info("Stats to be saved :\(statsResponseModel) at path : \(path)")
        
        var buffer: ByteBuffer =  ByteBufferAllocator().buffer(capacity: 1024)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            try JSONEncoder().encode(statsResponseModel, into: &buffer)
        }
        catch {
            return eventLoop.makeFailedFuture(error)
        }
        
        return isDirectoryExists(path: filePath + directoryPath).flatMapError { _ in
            self.createDirectory(path: self.filePath + directoryPath)
        }.flatMap { _ -> EventLoopFuture<NIOFileHandle> in
            fileIO.openFile(path: path, mode: .write, flags: .allowFileCreation(), eventLoop: self.eventLoop)
        }
        .flatMap { fileHandle -> EventLoopFuture<Void> in
            fileIO.write(fileHandle: fileHandle, buffer: buffer, eventLoop: self.eventLoop)
                .always { _ in
                    do {
                        try fileHandle.close()
                    }
                    catch {
                        self.logger.info("Error: \(error)")
                    }
                }
        }
        .flatMap { fileHandle -> EventLoopFuture<Void> in
            self.purgeOldDataIfNeeded()
        }
    }
    
    /// Purges the old data if needed.
    /// - Returns: An event loop future that resolves to `Void` when the old data is purged.
    public func purgeOldDataIfNeeded() -> EventLoopFuture<Void> {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        return removeDirectoriesOlderThan(twoDaysAgo)
    }
    
    /// Removes the directories that are older than the specified date.
    /// - Parameter date: A date that specifies the threshold for removing the directories.
    /// - Returns: An event loop future that resolves to `Void` when the directories are removed.
    private func removeDirectoriesOlderThan(_ date: Date) -> EventLoopFuture<Void> {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        // Get the day
        dateFormatter.dateFormat = "dd"
        let day = Int(dateFormatter.string(from: date))!
        logger.info("Trying to purge old data :\(date) \(day)")
        
        let fileIO = NonBlockingFileIO(threadPool: .singleton)
        return fileIO.listDirectory(path: filePath, eventLoop: eventLoop).flatMap { entries in
            let removeOperations = entries.compactMap { entry -> EventLoopFuture<Void>? in
                if let entryDay = Int(entry.name), entryDay < day {
                    self.logger.info("Removing file: \(self.filePath + "/" + entry.name)")
                    return fileIO.remove(path: self.filePath + "/" + entry.name, eventLoop: self.eventLoop)
                } else {
                    return nil
                }
            }
            return EventLoopFuture.andAllSucceed(removeOperations, on: self.eventLoop)
        }
    }
    
    /// gets the directory path based on the current date and time.
    private func getDirectoryPath() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        
        // Get the day
        dateFormatter.dateFormat = "dd"
        let day = dateFormatter.string(from: now)
        
        // Get the hour
        dateFormatter.dateFormat = "HH"
        let hour = dateFormatter.string(from: now)
        
        // Create the file path
        let directoryPath = "/\(day)/\(hour)"

        return directoryPath
    }
    
    /// gets the timestamp based on the current date and time.
    private func getTimestamp() -> String {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions.insert(.withFractionalSeconds)
        // Get the ISO 8601 timestamp
        let timestamp = dateFormatter.string(from: now)
        return timestamp
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
}
