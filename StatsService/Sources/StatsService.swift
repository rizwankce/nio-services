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
    
    @Option(name: .long,  help: "Ping Server Host to connect")
    var pingHost: String?

    @Option(name: .long, help: "Ping Server Port number to connect")
    var pingPort: Int?

    @Option(name: .shortAndLong, help: "Host to bind ")
    var host: String?
    
    @Option(name: .shortAndLong, help: "Port number to bind")
    var port: Int?
    
    @Argument(help: "Delay to access the ping server (in milli seconds)")
    var delay: Int

    mutating func run() throws {
        let clientHost = pingHost ?? "localhost"
        let clientPort = pingPort ?? 2345
        let serverHost = host ?? "localhost"
        let serverPort = port ?? 2346
        let server = StatsServer(delay: delay, clientHost: clientHost, clientPort: clientPort, host: serverHost, port: serverPort)
        try server.run()
    }
}
