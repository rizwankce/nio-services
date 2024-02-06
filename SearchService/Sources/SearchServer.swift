//
//  SearchServer.swift
//
//
//  Created by Rizwan on 06/02/24.
//

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1
import swift_polis

public class SearchServer {
    let eventLoopGroup: MultiThreadedEventLoopGroup
    let serverBootstrap: ServerBootstrap
    let host: String
    let port: Int
    let polisUrl: String

    init(host: String, port: Int, polisUrl: String) {
        self.host = host
        self.port = port
        self.polisUrl = polisUrl
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1) // threads can be System.coreCount
        let searchChannelHandler = SearchChannelHandler()
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
        print("Server started and listening on \(serverChannel.localAddress!)")

        try serverChannel.closeFuture.wait()
        print("Server closed")
    }

    func getPolisData() {
        
    }
}