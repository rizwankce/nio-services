// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import NIOCore
import NIOPosix
import NIOHTTP1

/// The main struct representing the StatsService command-line interface.
///
/// This struct conforms to the `ParsableCommand` protocol, allowing it to be used as a command-line tool.
/// It provides options and arguments for configuring and running the StatsService.
@main
struct StatsService: ParsableCommand {
    
    /// The configuration for the StatsService command-line interface.
    static let configuration = CommandConfiguration(abstract: "Statstics Service CLI")
    
    /// A flag indicating whether to print status updates while the server is running.
    @Flag(name: .shortAndLong, help: "Print status updates while server running.")
    var verbose = false
    
    /// The ping server host to connect to.
    @Option(name: .long,  help: "Ping Server Host to connect")
    var pingHost: String?
    
    /// The ping server port number to connect to.
    @Option(name: .long, help: "Ping Server Port number to connect")
    var pingPort: Int?
    
    /// The host to bind the server to.
    @Option(name: .shortAndLong, help: "Host to bind ")
    var host: String?
    
    /// The port number to bind the server to.
    @Option(name: .shortAndLong, help: "Port number to bind")
    var port: Int?
    
    /// The delay to access the ping server (in milliseconds).
    @Argument(help: "Delay to access the ping server (in milli seconds)")
    var delay: Int
    
    /// Runs the StatsService command.
    ///
    /// This method is called when the command is executed.
    /// It creates a `StatsServer` instance with the provided configuration and runs the server.
    mutating func run() throws {
        let clientHost = pingHost ?? "localhost"
        let clientPort = pingPort ?? 2345
        let serverHost = host ?? "localhost"
        let serverPort = port ?? 2346
        let server = StatsServer(delay: delay, clientHost: clientHost, clientPort: clientPort, host: serverHost, port: serverPort)
        try server.run()
    }
}
