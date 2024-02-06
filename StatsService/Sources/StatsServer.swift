//
//  StatsServer.swift
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
    var pingResponseTime: PingResponseTime

    init(delay: Int, clientHost: String, clientPort: Int, host: String, port: Int) {
        self.delay = delay
        self.pingResponseTime = PingResponseTime()
        let pingChannelHandler = PingChannelHandler(delay: delay, pingResponseTime: pingResponseTime)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1) // threads can be System.coreCount
        self.clientBootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers(position: .first,
                                                       leftOverBytesStrategy: .fireError).flatMap {
                    channel.pipeline.addHandler(pingChannelHandler)
                }
            }
        let statesChannelHandler = StatesChannelHandler(pingResponseTime: pingResponseTime)
        self.serverBootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true)
                    .flatMap {
                        channel.pipeline.addHandler(statesChannelHandler)
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
        pingResponseTime.startTime = Date()

        let clientChannel = try clientBootstrap.connect(host: clientHost, port: clientPort).wait()
        print("Client started and connecting to \(clientChannel.localAddress!)")

        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/ping")

//        I don't know why `scheduleRepeatedTask` is not working ...
//        clientChannel.eventLoop.next().scheduleRepeatedTask(initialDelay: .zero, delay: .seconds(Int64(delay))) { task in
//            clientChannel.write(HTTPClientRequestPart.head(requestHead), promise: nil)
//            _ = clientChannel.writeAndFlush(HTTPClientRequestPart.end(nil))
//        }

        #warning("scheduling task with delay not triggering the request.. :(")
        clientChannel.write(HTTPClientRequestPart.head(requestHead), promise: nil)
        _ = clientChannel.writeAndFlush(HTTPClientRequestPart.end(nil))

        //try clientChannel.closeFuture.wait()

        let serverChannel = try serverBootstrap.bind(host: host, port: port).wait()
        print("Server started and listening on \(serverChannel.localAddress!)")

        try serverChannel.closeFuture.wait()
        print("Server closed")
    }
}
