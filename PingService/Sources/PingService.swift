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

    @Option(name: .shortAndLong, help: "Host to bind ")
    var host: String?

    @Option(name: .shortAndLong, help: "Port number to bind")
    var port: Int?

    @Argument(help: "Size of window to get average, min and max response times")
    var windowSize: Int

    @Argument(help: "File Path for saving the response times")
    var filePath: String

    mutating func run() throws {
        let bindingHost = host ?? "localhost"
        let bindingPort = port ?? 2345

        let pingServer = PingServer(host: bindingHost, port: bindingPort, windowSize: windowSize, filePath: filePath)
        try pingServer.run()
    }
}
