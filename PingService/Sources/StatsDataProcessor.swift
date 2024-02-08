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

public class StatsDataProcessor {
    let logger = Logger(label: "stats-data-processor-nio")
    private let filePath: String
    private let fileSystem: FileSystem = FileSystem.shared

    init(filePath: String) {
        self.filePath = filePath
    }

    public func export(_ statsResponseModel: StatsResponseModel) async throws {
        try await purgeOldDataIfNeeded()

        let directoryPath = getDirectoryPath()
        let timestamp = getTimestamp()

        let path = filePath + directoryPath + "/\(timestamp).json"
        logger.info("Stats to be saved :\(statsResponseModel) at path : \(path)")

        do {
            if await !isDirectoryExists(atPath: filePath + directoryPath) {
                try await FileSystem.shared.createDirectory(at: FilePath(filePath + directoryPath), withIntermediateDirectories: true)
            }
            try await FileSystem.shared.withFileHandle(
                forWritingAt:  FilePath(path),
                options: .newFile(replaceExisting: true)
            ) { file in
                var buffer: ByteBuffer =  ByteBufferAllocator().buffer(capacity: 1024)
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                try JSONEncoder().encode(statsResponseModel, into: &buffer)
                try await file.write(contentsOf: buffer.readableBytesView, toAbsoluteOffset: 0)
            }
        }
        catch {
            logger.error("error \(error)")
        }
    }

    public func purgeOldDataIfNeeded() async throws {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        try await removeDirectoriesOlderThan(twoDaysAgo)
    }

    private func removeDirectoriesOlderThan(_ date: Date) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        // Get the day
        dateFormatter.dateFormat = "dd"
        let day = Int(dateFormatter.string(from: date))!
        logger.info("Trying to purge old data :\(date) \(day)")
        try await FileSystem.shared.withDirectoryHandle(atPath: FilePath(filePath)) { directory in
            for try await entry in directory.listContents() {
                if entry.type == .directory && day >= Int(entry.name.string)! {
                    logger.info("removing old directory at path \(entry.path)")
                    try await FileSystem.shared.removeItem(at: entry.path)
                }
            }
        }
    }

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
        let directoryPath = "\(day)/\(hour)"

        return directoryPath
    }

    private func getTimestamp() -> String {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions.insert(.withFractionalSeconds)
        // Get the ISO 8601 timestamp
        let timestamp = dateFormatter.string(from: now)
        return timestamp
    }

    private func isDirectoryExists(atPath path: String) async -> Bool {
        do {
            return try await FileSystem.shared.withDirectoryHandle(atPath: FilePath(path)) { directory -> Bool in
                _ = try await directory.info()
                return true
            }
        }
        catch {
            return false
        }
    }
}
