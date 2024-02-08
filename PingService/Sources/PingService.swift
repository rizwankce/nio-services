// The Swift Programming Language
// https://docs.swift.org/swift-book

import NIOCore
import NIOPosix
import NIOHTTP1
import ArgumentParser

/// The main struct representing the Ping Service command-line interface.
///
/// This struct conforms to the `ParsableCommand` protocol, allowing it to be used as a command-line tool.
/// It provides options and arguments for configuring and running the Ping Service.
@main
struct PingService: ParsableCommand {
    /// The configuration for the Ping Service command-line tool.
    static let configuration = CommandConfiguration(abstract: "Ping Service CLI")
    
    /// A flag indicating whether to print status updates while the server is running.
    @Flag(name: .shortAndLong, help: "Print status updates while server running.")
    var verbose = false
    
    /// The host to bind the server to.
    @Option(name: .shortAndLong, help: "Host to bind ")
    var host: String?
    
    /// The port number to bind the server to.
    @Option(name: .shortAndLong, help: "Port number to bind")
    var port: Int?
    
    /// The size of the window to get average, minimum, and maximum response times.
    @Argument(help: "Size of window to get average, min and max response times")
    var windowSize: Int
    
    /// The file path for saving the response times.
    @Argument(help: "File Path for saving the response times")
    var filePath: String
    
    /// Runs the Ping Service.
    ///
    /// This method is called when the Ping Service command-line tool is executed.
    /// It initializes a `PingServer` instance with the provided host, port, window size, and file path,
    /// and then runs the server.
    mutating func run() throws {
        let bindingHost = host ?? "localhost"
        let bindingPort = port ?? 2345
        
        let pingServer = PingServer(host: bindingHost, port: bindingPort, windowSize: windowSize, filePath: filePath)
        try pingServer.run()
    }
}
