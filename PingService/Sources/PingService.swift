// The Swift Programming Language
// https://docs.swift.org/swift-book

import NIOCore
import NIOPosix
import NIOHTTP1
import ArgumentParser

@main
struct PingService: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Ping Service CLI")

    @Flag(name: .shortAndLong, help: "Print status updates while server running.")
    var verbose = false

    @Option(name: .shortAndLong, help: "IP Address to bind ")
    var ipAddress: String?

    @Option(name: .shortAndLong, help: "Port number to bind")
    var port: Int?

    mutating func run() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1) // threads can be System.coreCount
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true)
                    .flatMap{
                        channel.pipeline.addHandler(PingChannelHandler())
                    }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

        defer {
            try! group.syncShutdownGracefully()
        }

        let bindingIP = ipAddress ?? "localhost"
        let bindingPort = port ?? 2345

        let channel = try bootstrap.bind(host: bindingIP, port: bindingPort).wait()
        print("Server started and listening on \(channel.localAddress!)")

        try channel.closeFuture.wait()
        print("Server closed")
    }
}
