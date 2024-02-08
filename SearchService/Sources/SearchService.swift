// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Logging
import NIOCore
import NIOPosix
import NIOHTTP1

/// The main struct representing the Search Service command-line interface.
///
/// This struct conforms to the `ParsableCommand` protocol, allowing it to be used as a command-line tool.
/// It provides options and flags for configuring the behavior of the Search Service.
@main
struct SearchService: ParsableCommand {
    
    /// The configuration for the Search Service command-line tool.
    static let configuration = CommandConfiguration(abstract: "Statstics Service CLI")
    
    /// A flag indicating whether to print status updates while the server is running.
    @Flag(name: .shortAndLong, help: "Print status updates while server running.")
    var verbose = false
    
    /// The host to bind the server to.
    @Option(name: .shortAndLong, help: "Host to bind ")
    var host: String?
    
    /// The port number to bind the server to.
    @Option(name: .shortAndLong, help: "Port number to bind")
    var port: Int?
    
    /// The URL to download polis data from.
    @Option(name: .shortAndLong, help: "URL to download polis data from")
    var url: String?
    
    /// The file path to store the copied polis data.
    @Option(name: .long, help: "File Path to store the copied polis data")
    var polisRemoteDataFilePath: String
    
    /// The file path to use as the source for polis resource (for testing purpose only).
    @Option(name: .long, help: "**For testing purpose only.** Will use the path as source for polis resource")
    var polisStaticDataFilePath: String?
    
    /// Runs the Search Service.
    ///
    /// This method is called when the Search Service command-line tool is executed.
    /// It initializes a `SearchServer` instance with the provided configuration and runs the server.
    mutating func run() throws {
        let serverHost = host ?? "localhost"
        let serverPort = port ?? 2347
        let server = SearchServer(host: serverHost, port: serverPort, polisUrl: url, polisRemoteFilePath: polisRemoteDataFilePath, polisDatFilePath: polisStaticDataFilePath)
        try server.run()
    }
}
