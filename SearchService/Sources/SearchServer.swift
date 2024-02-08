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

public class SearchServer {
    let logger = Logger(label: "search-service-nio")
    let eventLoopGroup: MultiThreadedEventLoopGroup
    let serverBootstrap: ServerBootstrap
    let host: String
    let port: Int
    let polisUrl: String
    let polisDataProvider: PolisDataProvider
    let polisDataDownloader: PolisDataDownloader

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
