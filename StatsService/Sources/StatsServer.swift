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

public struct StatsServer {
    let eventLoopGroup: MultiThreadedEventLoopGroup
    var clientBootstrap: ClientBootstrap
    let clientHost: String
    let clientPort: Int

    init(clientHost: String, clientPort: Int) {
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1) // threads can be System.coreCount
        self.clientBootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers(position: .first,
                                                       leftOverBytesStrategy: .fireError).flatMap {
                    channel.pipeline.addHandler(PingChannelHandler())
                }
            }
        self.clientHost = clientHost
        self.clientPort = clientPort
    }

    mutating func run() throws {
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
        }

        let channel = try clientBootstrap.connect(host: clientHost, port: clientPort).wait()
        print("Client started and connecting to \(channel.localAddress!)")

        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/ping")
        channel.write(HTTPClientRequestPart.head(requestHead), promise: nil)
        _ = channel.writeAndFlush(HTTPClientRequestPart.end(nil))

        try channel.closeFuture.wait()
    }
}
