//
//  StatsServer.swift
//
//
//  Created by Rizwan on 05/02/24.
//

import Foundation
import Logging
import NIOCore
import NIOPosix
import NIOHTTP1

/// A class representing a Stats Server.
public class StatsServer {
    /// The logger for the Stats Server.
    let logger = Logger(label: "stats-service-nio")
    
    /// The event loop group for handling network events.
    let eventLoopGroup: MultiThreadedEventLoopGroup
    
    /// The client bootstrap for establishing connections to clients.
    let clientBootstrap: ClientBootstrap
    
    /// The server bootstrap for accepting incoming connections.
    let serverBootstrap: ServerBootstrap
    
    /// The host address of the client.
    let clientHost: String
    
    /// The port number of the client.
    let clientPort: Int
    
    /// The host address of the server.
    let host: String
    
    /// The port number of the server.
    let port: Int
    
    /// The delay in milliseconds between sending ping requests.
    let delay: Int64
    
    /// The object for tracking ping response time.
    var pingResponseTime: PingResponseTime
    
    /// Initializes a Stats Server with the specified parameters.
    /// - Parameters:
    ///   - delay: The delay in milliseconds between sending ping requests.
    ///   - clientHost: The host address of the client.
    ///   - clientPort: The port number of the client.
    ///   - host: The host address of the server.
    ///   - port: The port number of the server.
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
    
    /// Runs the Stats Server.
    /// - Throws: An error if the server fails to start or encounters an error during execution.
    func run() throws {
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
        }
        pingResponseTime.startTime = Date()
        
        eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(0), delay: .milliseconds(delay)) { _ in
            self.bootstrapPingRequest()
        }
        
        let serverChannel = try serverBootstrap.bind(host: host, port: port).wait()
        logger.info("Server started and listening on \(serverChannel.localAddress!)")
        
        try serverChannel.closeFuture.wait()
        logger.info("Server closed")
    }
    
    /// Establishes a connection to the client and sends a ping request.
    func bootstrapPingRequest() {
        clientBootstrap.connect(host: clientHost, port: clientPort).whenComplete { result in
            switch result {
                case .success(let success):
                    self.logger.info("Client started and connecting to \(success.localAddress!)")
                    self.sendPingRequest(success).whenComplete { result in
                        switch result {
                            case .success:
                                self.logger.info("Request was successful")
                            case .failure(let error):
                                self.logger.error("Request failed with error: \(error)")
                        }
                    }
                case .failure(let failure):
                    self.logger.error("Client connection failed with error: \(failure)")
            }
        }
    }
    
    /// Sends a ping request to the client.
    /// - Parameter clientChannel: The channel representing the client connection.
    /// - Returns: An `EventLoopFuture` that completes when the ping request is sent.
    func sendPingRequest(_ clientChannel: Channel) -> EventLoopFuture<Void> {
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/ping")
        clientChannel.write(HTTPClientRequestPart.head(requestHead), promise: nil)
        return clientChannel.writeAndFlush(HTTPClientRequestPart.end(nil))
    }
}
