// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import NIOCore
import NIOPosix
import NIOHTTP1

@main
struct StatsService: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Statstics Service CLI")
    
    @Flag(name: .shortAndLong, help: "Print status updates while server running.")
    var verbose = false
    
    @Option(name: .shortAndLong, help: "Host to bind ")
    var host: String?
    
    @Option(name: .shortAndLong, help: "Port number to bind")
    var port: Int?
    
    mutating func run() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1) // threads can be System.coreCount
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers(position: .first,
                                                       leftOverBytesStrategy: .fireError).flatMap {
                    channel.pipeline.addHandler(PingChannelHandler())
                }
            }
        
        defer {
            try! group.syncShutdownGracefully()
        }
        
        let defaultHost = host ?? "localhost"
        let defaultPort = port ?? 2345
        
        let channel = try bootstrap.connect(host: defaultHost, port: defaultPort).wait()
        print("Client started and connecting to \(channel.localAddress!)")

        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/ping")
        channel.write(HTTPClientRequestPart.head(requestHead), promise: nil)
        _ = channel.writeAndFlush(HTTPClientRequestPart.end(nil))

        try channel.closeFuture.wait()
    }
}
