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
    
    mutating func run() throws {
        let clientHost = pingHost ?? "localhost"
        let clientPort = pingPort ?? 2345
        var server = StatsServer(clientHost: clientHost, clientPort: clientPort)
        try server.run()
    }
}
