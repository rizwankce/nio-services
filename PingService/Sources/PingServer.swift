//
//  PingServer.swift
//
//
//  Created by Rizwan on 05/02/24.
//

import Foundation
import Logging
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOFoundationCompat
import NIOFileSystem

/// A class representing a Ping server.
public class PingServer {
    /// The logger used for logging server events.
    let logger = Logger(label: "ping-service-nio")
    
    /// The host address of the server.
    let host: String
    
    /// The port number on which the server listens.
    let port: Int
    
    /// The event loop group used by the server.
    let eventLoopGroup: MultiThreadedEventLoopGroup
    
    /// The server bootstrap used to configure the server.
    let serverBootstrap: ServerBootstrap
    
    /// The size of the window used for tracking ping response times.
    let windowSize: Int
    
    /// The object responsible for tracking ping response times.
    let pingResponseTime: PingResponseTime
    
    /// The file path where statistics data is stored.
    let filePath: String
    
    /// The object responsible for processing and exporting statistics data in JSON format.
    let jsonExporter: StatsDataProcessor
    
    /// Initializes a new instance of the `PingServer` class.
    /// - Parameters:
    ///   - host: The host address of the server.
    ///   - port: The port number on which the server listens.
    ///   - windowSize: The size of the window used for tracking ping response times.
    ///   - filePath: The file path where statistics data is stored.
    public init(host: String, port: Int, windowSize: Int, filePath: String) {
        self.host = host
        self.port = port
        self.windowSize = windowSize
        self.pingResponseTime = PingResponseTime()
        self.filePath = filePath
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount) // threads can be System.coreCount
        self.jsonExporter = StatsDataProcessor(filePath: filePath, eventLoop: eventLoopGroup.next())
        let pingChannelHandler = PingChannelHandler(pingResponseTime: pingResponseTime)
        self.serverBootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true)
                    .flatMap{
                        channel.pipeline.addHandler(pingChannelHandler)
                    }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
    
    /// Runs the Ping server.
    /// - Throws: An error if the server fails to start or encounters an error during execution.
    public func run() throws {
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
        }
        
        let channel = try serverBootstrap.bind(host: host, port: port).wait()
        logger.info("Server started and listening on \(channel.localAddress!)")
        
        eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .minutes(5), delay: .minutes(5)) { task in
            self.saveStatisticsToFile()
        }
        
        eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .hours(48), delay: .hours(48)) { task in
            self.purgeOldStatistics()
        }
        
        try channel.closeFuture.wait()
        logger.info("Server closed")
    }
    
    /// Saves the statistics data to a file.
    func saveStatisticsToFile() {
        logger.info("Automatic backup started ...")
        jsonExporter.export(pingResponseTime.getStatsResponseModel()).whenComplete { result in
            switch result {
                case .success(let success):
                    self.logger.info("JSON Export Success")
                case .failure(let failure):
                    self.logger.info("JSON Export failed: \(failure)")
            }
        }
    }
    
    /// Purges old statistics data if needed.
    func purgeOldStatistics() {
        logger.info("Automatic purging old statistics started ...")
        jsonExporter.purgeOldDataIfNeeded().whenComplete { result in
            switch result {
                case .success(let success):
                    self.logger.info("Purge old data success")
                case .failure(let failure):
                    self.logger.info("Purge old data failed: \(failure)")
            }
        }
    }
}
