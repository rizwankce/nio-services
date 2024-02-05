//
//  File.swift
//
//
//  Created by Rizwan on 05/02/24.
//

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1

public class StatsServer {
    let eventLoopGroup: MultiThreadedEventLoopGroup
    let clientBootstrap: ClientBootstrap
    let serverBootstrap: ServerBootstrap
    let clientHost: String
    let clientPort: Int
    let host: String
    let port: Int
    let delay: Int

    init(delay: Int, clientHost: String, clientPort: Int, host: String, port: Int) {
        self.delay = delay
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1) // threads can be System.coreCount
        self.clientBootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers(position: .first,
                                                       leftOverBytesStrategy: .fireError).flatMap {
                    channel.pipeline.addHandler(PingChannelHandler(delay: delay))
                }
            }
        self.serverBootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true)
                    .flatMap {
                        channel.pipeline.addHandler(StatesChannelHandler())
                    }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        self.clientHost = clientHost
        self.clientPort = clientPort
        self.host = host
        self.port = port
    }

    func run() throws {
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
        }

        let clientChannel = try clientBootstrap.connect(host: clientHost, port: clientPort).wait()
        print("Client started and connecting to \(clientChannel.localAddress!)")

        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/ping")

        #warning("scheduling taks with delay not triggering the request.. :(")
        clientChannel.eventLoop.scheduleTask(in: .milliseconds(Int64(delay))) {
            clientChannel.write(HTTPClientRequestPart.head(requestHead), promise: nil)
            _ = clientChannel.writeAndFlush(HTTPClientRequestPart.end(nil))
        }

        //try clientChannel.closeFuture.wait()

        let serverChaneel = try serverBootstrap.bind(host: host, port: port).wait()
        print("Server started and listening on \(serverChaneel.localAddress!)")

        try serverChaneel.closeFuture.wait()
        print("Server closed")
    }
}
