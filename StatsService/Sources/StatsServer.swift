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
    let delay: Int64
    var pingResponseTime: PingResponseTime

    init(delay: Int, clientHost: String, clientPort: Int, host: String, port: Int) {
        self.delay = Int64(delay)
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

        eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(0), delay: .milliseconds(delay)) { _ in
            self.bootstrapPingRequest()
        }

        let serverChannel = try serverBootstrap.bind(host: host, port: port).wait()
        print("Server started and listening on \(serverChannel.localAddress!)")

        try serverChannel.closeFuture.wait()
        print("Server closed")
    }

    func bootstrapPingRequest() {
        clientBootstrap.connect(host: clientHost, port: clientPort).whenComplete { result in
            switch result {
                case .success(let success):
                    print("Client started and connecting to \(success.localAddress!)")
                    self.sendPingRequest(success).whenComplete { result in
                        switch result {
                        case .success:
                            print("Request was successful")
                        case .failure(let error):
                            print("Request failed with error: \(error)")
                        }
                    }
                case .failure(let failure):
                    print("Client connection failed with error: \(failure)")
            }
        }
    }

    func sendPingRequest(_ clientChannel: Channel) -> EventLoopFuture<Void> {
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/ping")
        clientChannel.write(HTTPClientRequestPart.head(requestHead), promise: nil)
        return clientChannel.writeAndFlush(HTTPClientRequestPart.end(nil))
    }
}
