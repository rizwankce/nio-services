//
//  PingServer.swift
//  
//
//  Created by Rizwan on 05/02/24.
//

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOFoundationCompat
import NIOFileSystem

public class PingServer {
    let host: String
    let port: Int
    let eventLoopGroup: MultiThreadedEventLoopGroup
    let serverBootstrap: ServerBootstrap
    let windowSize: Int
    let pingResponseTime: PingResponseTime
    let filePath: String
    let jsonExporter: StatsDataProcessor

    init(host: String, port: Int, windowSize: Int, filePath: String) {
        self.host = host
        self.port = port
        self.windowSize = windowSize
        self.pingResponseTime = PingResponseTime()
        self.filePath = filePath
        self.jsonExporter = StatsDataProcessor(filePath: filePath)
        let pingChannelHandler = PingChannelHandler(pingResponseTime: pingResponseTime)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount) // threads can be System.coreCount
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

    func run() throws {
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
        }

        let channel = try serverBootstrap.bind(host: host, port: port).wait()
        print("Server started and listening on \(channel.localAddress!)")

        eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .minutes(5), delay: .minutes(5)) { task in
            self.saveStatisticsToFile()
        }

        eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .hours(48), delay: .hours(48)) { task in
            self.purgeOldStatistics()
        }

        try channel.closeFuture.wait()
        print("Server closed")
    }

    func saveStatisticsToFile() {
        print("Automatic backup started ...")
        Task{
            try await jsonExporter.export(pingResponseTime.getStatsResponseModel())
        }
    }

    func purgeOldStatistics() {
        print("Automatic purging old statistics started ...")
        Task {
            try await jsonExporter.purgeOldDataIfNeeded()
        }
    }
}
