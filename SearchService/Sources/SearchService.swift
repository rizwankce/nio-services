// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import NIOCore
import NIOPosix
import NIOHTTP1

@main
struct SearchService: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Statstics Service CLI")

    @Flag(name: .shortAndLong, help: "Print status updates while server running.")
    var verbose = false

    @Option(name: .shortAndLong, help: "Host to bind ")
    var host: String?

    @Option(name: .shortAndLong, help: "Port number to bind")
    var port: Int?

    @Argument(help: "URL to download polis data from")
    var url: String

    mutating func run() throws {
        let serverHost = host ?? "localhost"
        let serverPort = port ?? 2347
        let server = SearchServer(host: serverHost, port: serverPort, polisUrl: url)
        try server.run()
    }
}
