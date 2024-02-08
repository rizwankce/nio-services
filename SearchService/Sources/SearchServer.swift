//
//  SearchServer.swift
//
//
//  Created by Rizwan on 06/02/24.
//

import Foundation
import Logging
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOFoundationCompat
import swift_polis

/// The `SearchServer` class represents a server that handles search requests.
public class SearchServer {
    /// The logger used for logging server events.
    let logger = Logger(label: "search-service-nio")
    
    /// The event loop group used by the server.
    let eventLoopGroup: MultiThreadedEventLoopGroup
    
    /// The server bootstrap used to configure and start the server.
    let serverBootstrap: ServerBootstrap
    
    /// The host address on which the server listens.
    let host: String
    
    /// The port number on which the server listens.
    let port: Int
    
    /// The URL of the Polis service.
    let polisUrl: String
    
    /// The data provider for Polis.
    let polisDataProvider: PolisDataProvider
    
    /// The data downloader for Polis.
    let polisDataDownloader: PolisDataDownloader
    
    /// Initializes a new instance of `SearchServer`.
    /// - Parameters:
    ///   - host: The host address on which the server listens.
    ///   - port: The port number on which the server listens.
    ///   - polisUrl: The URL of the Polis service. If `nil`, a default test URL will be used.
    ///   - polisRemoteFilePath: The remote file path for Polis data.
    ///   - polisDatFilePath: The local file path for Polis data. If `nil`, the remote file path will be used.
    init(host: String, port: Int, polisUrl: String?, polisRemoteFilePath: String, polisDatFilePath: String?) {
        self.host = host
        self.port = port
        self.polisUrl = polisUrl ?? PolisConstants.testBigBangPolisDomain
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1) // threads can be System.coreCount
        self.polisDataProvider = PolisDataProvider(filePath: polisDatFilePath ?? polisRemoteFilePath)
        self.polisDataDownloader = PolisDataDownloader(polisUrl: self.polisUrl, filePath: polisRemoteFilePath, eventLoopGroup: self.eventLoopGroup)
        let searchChannelHandler = SearchChannelHandler(polisDataProvider: polisDataProvider)
        self.serverBootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true)
                    .flatMap {
                        channel.pipeline.addHandler(searchChannelHandler)
                    }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
    
    /// Runs the server.
    /// - Throws: An error if the server fails to start or encounters an error during execution.
    func run() throws {
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
        }
        
        let serverChannel = try serverBootstrap.bind(host: host, port: port).wait()
        logger.info("Server started and listening on \(serverChannel.localAddress!)")
        
        polisDataDownloader.initiateAsyncDownload().whenComplete { result in
            switch result {
                case .success(let success):
                    self.logger.info("POLIS data successfully downloaded")
                case .failure(let failure):
                    self.logger.error("Error in downloading POLIS data: \(failure)")
            }
        }
        
        try serverChannel.closeFuture.wait()
        logger.info("Server closed")
    }
}
