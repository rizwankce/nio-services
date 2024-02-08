//
//  PolisDataDownloader.swift
//
//
//  Created by Rizwan on 08/02/24.
//

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOFileSystem
import NIOFoundationCompat
import NIOTransportServices
import swift_polis
import AsyncHTTPClient

public enum PolisDataDownloaderError: Error, Equatable {
    case resourceNotFound
    case failedToDownload
}

final class PolisDataDownloader {
    let polisUrl: String
    let filePath: String
    let eventLoopGroup: MultiThreadedEventLoopGroup
    let eventLoop: EventLoop
    let polisRemoteResource: PolisRemoteResourceFinder?
    let polisFileResource: PolisFileResourceFinder?
    let polisVersion: String
    let polisDataProvider: PolisDataProvider

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

    func initiateAsyncDownload() -> EventLoopFuture<Void> {
        downloadConfigurationFile().flatMap {
            self.downloadDirectoryFile().flatMap {
                self.downloadObservingFacilitiesFile().flatMap {
                    self.downloadAllObservingFacilitiesFile()
                }
            }
        }
    }

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

    func downloadConfigurationFile() -> EventLoopFuture<Void> {
        guard let polisRemoteResource = polisRemoteResource else {
            return eventLoop.makeFailedFuture(PolisDataDownloaderError.resourceNotFound)
        }

        let url = polisRemoteResource.configurationURL()
        let path = polisFileResource!.configurationFile()
        return downloadPolisFile(from: url, to: path)
    }

    func downloadDirectoryFile() -> EventLoopFuture<Void> {
        guard let polisRemoteResource = polisRemoteResource else {
            return eventLoop.makeFailedFuture(PolisDataDownloaderError.resourceNotFound)
        }

        let url = polisRemoteResource.polisProviderDirectoryURL()
        let path = polisFileResource!.polisProviderDirectoryFile()
        return downloadPolisFile(from: url, to: path)
    }

    func downloadObservingFacilitiesFile() -> EventLoopFuture<Void> {
        guard let polisRemoteResource = polisRemoteResource else {
            return eventLoop.makeFailedFuture(PolisDataDownloaderError.resourceNotFound)
        }

        let url = polisRemoteResource.observingFacilitiesDirectoryURL()
        let path = polisFileResource!.observingFacilitiesDirectoryFile()
        return downloadPolisFile(from: url, to: path)
    }

    func downloadPolisFile(from: String, to path: String) -> EventLoopFuture<Void> {
        return downloadJSON(urlString: from)
            .flatMap { buffer -> EventLoopFuture<Void> in
                self.saveJSONFile(path: path, byteBuffer: buffer)
            }
    }

    func downloadJSON(urlString: String) -> EventLoopFuture<ByteBuffer> {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return eventLoop.makeFailedFuture(URLError(.badURL))
        }
        let promise = eventLoop.makePromise(of: ByteBuffer.self)
        let httpClient = HTTPClient(eventLoopGroup: eventLoopGroup)

        httpClient.get(url: urlString).whenComplete { result in
            defer {
                _ = httpClient.shutdown()
            }
            switch result {
                case .success(let response):
                    guard var body = response.body else {
                        print("No body in response")
                        return
                    }

                    promise.succeed(body)
                    print("JSON downloaded successfully.")
                case .failure(let error):
                    promise.fail(error)
                    print("Failed to download JSON: \(error)")
            }
        }


        //        let group = NIOTSEventLoopGroup()
        //        let bootstrap = NIOTSConnectionBootstrap(group: group)
        //            .connectTimeout(.hours(1))
        //            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        //           // .tlsOptions(NWProtocolTLS.Options())
        //            .channelInitializer { channel in
        //                channel.pipeline.addHTTPClientHandlers().flatMap {
        //                    channel.pipeline.addHandler(HTTPResponseHandler(bufferPromise: promise))
        //                }
        //            }
        //        let bootstrap = ClientBootstrap(group: eventLoopGroup)
        //        .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        //        .channelInitializer { channel in
        //            return
        //                channel.pipeline.addHTTPClientHandlers(position: .first,
        //                                                       leftOverBytesStrategy: .fireError).flatMap {
        //                    channel.pipeline.addHandler(HTTPResponseHandler(bufferPromise: promise))
        //                }
        //        }

        //        bootstrap.connect(host: "test.polis.observer", port: url.port ?? 80).whenSuccess { channel in
        //            print("Triggering request to download \(urlString) with path \(url.path), port: \(url.port)")
        //            var request = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/polis/polis.json")
        //            request.headers.add(name: "Host", value: url.host ?? "")
        //            request.headers.add(name: "Accept", value: "application/json")
        //            channel.writeAndFlush(HTTPClientRequestPart.head(request), promise: nil)
        //            channel.writeAndFlush(HTTPClientRequestPart.end(nil), promise: nil)
        //        }

        return promise.futureResult
    }

    func createDirectory(path: String) -> EventLoopFuture<Void> {
        print("Creating directory at path: \(path)")
        let fileIO = NonBlockingFileIO(threadPool: .singleton)
        return fileIO.createDirectory(path: path, withIntermediateDirectories: true, mode: S_IRWXU, eventLoop: eventLoop)
    }

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

    func saveJSONFile(path: String, byteBuffer: ByteBuffer) -> EventLoopFuture<Void> {
        print("Saving JSON file at path: \(path)")
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

                        }
                    }
            }
        return writeFuture
    }
}

class HTTPResponseHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPClientResponsePart
    public typealias OutboundOut = HTTPClientRequestPart

    private let bufferPromise: EventLoopPromise<ByteBuffer>

    init(bufferPromise: EventLoopPromise<ByteBuffer>) {
        self.bufferPromise = bufferPromise
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let httpResponsePart = unwrapInboundIn(data)
        print(httpResponsePart)
        switch httpResponsePart {
            case .head(let header):
                if header.status == .movedPermanently, let location = header.headers.first(name: "Location") {
                    // Follow the redirect

                }
            case .body(let buffer):
                print("Received JSON: \(buffer)")
                bufferPromise.succeed(buffer)
            case .end:
                break
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        bufferPromise.fail(error)
    }
}
