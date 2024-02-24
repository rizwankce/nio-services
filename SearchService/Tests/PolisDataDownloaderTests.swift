//
//  PolisDataDownloaderTests.swift
//
//
//  Created by Rizwan on 24/02/24.
//

import Foundation
import XCTest
import NIO
import NIOFoundationCompat
import swift_polis

@testable import SearchService

final class PolisDataDownloaderTests: XCTestCase {
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    let filePath = FileManager.default.temporaryDirectory.path(percentEncoded: true)
    var downloader: PolisDataDownloader!
    var polisFileResource: PolisFileResourceFinder!

    override func setUp() {
        super.setUp()
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        downloader = PolisDataDownloader(
            polisUrl: PolisConstants.testBigBangPolisDomain,
            filePath: filePath,
            eventLoopGroup: eventLoopGroup
        )
        polisFileResource = downloader.polisFileResource
    }

    override func tearDown() {
        print(filePath)
        super.tearDown()
    }

    func isDirectoryExists(at path: String) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func isFileExists(at path: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path)
    }

    func testAllDownloadedDirectoriesCorrectly() throws {
        // When
        try downloader.initiateAsyncDownload().wait()

        // Then
        XCTAssertTrue(isDirectoryExists(at: polisFileResource.rootFolder()))
        XCTAssertTrue(isDirectoryExists(at: polisFileResource.baseFolder()))
        XCTAssertTrue(isDirectoryExists(at: polisFileResource.observingFacilitiesFolder()))
    }

    func testAllDownloadedFilesCorrectly() throws {
        // When
        try downloader.initiateAsyncDownload().wait()

        // Then
        XCTAssertTrue(isFileExists(at: polisFileResource.configurationFile()))
        XCTAssertTrue(isFileExists(at: polisFileResource.polisProviderDirectoryFile()))
        XCTAssertTrue(isFileExists(at: polisFileResource.observingFacilitiesDirectoryFile()))
    }
}
