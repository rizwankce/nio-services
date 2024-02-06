//
//  File.swift
//  
//
//  Created by Rizwan on 06/02/24.
//

import Foundation
import NIOFileSystem
import NIOCore

public class JSONExporter {
    let filePath: String

    init(filePath: String) {
        self.filePath = filePath
    }

    func getDirectoryPath() -> String {
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

    func getTimestamp() -> String {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions.insert(.withFractionalSeconds)
        // Get the ISO 8601 timestamp
        let timestamp = dateFormatter.string(from: now)
        return timestamp
    }

    func isDirectoryExsists(atPath path: String) async -> Bool {
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

    func export(_ statsResponseModel: StatsResponseModel) {
        let directoryPath = getDirectoryPath()
        let timestamp = getTimestamp()
        print(directoryPath, timestamp)
        let path = filePath + directoryPath + "/\(timestamp).json"
        print("Stats to be saved :\(statsResponseModel) at path : \(path)")

        Task {
            do {
                if await !isDirectoryExsists(atPath: filePath + directoryPath) {
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
                print(error)
            }
        }
    }
}
