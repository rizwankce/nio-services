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

    @Option(name: .shortAndLong, help: "IP Address to bind ")
    var ipAddress: String?

    @Option(name: .shortAndLong, help: "Port number to bind")
    var port: Int?

    mutating func run() throws {
        print("Hello, World!")
    }
}
