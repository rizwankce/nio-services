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


private final class PingChannelHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = self.unwrapInboundIn(data)
        switch requestPart {
            case .head(let request):
                if request.uri.unicodeScalars.starts(with: "/ping".unicodeScalars) {
                    let responseTime = Int64.random(in: 20 ... 5000)
                    context.eventLoop.scheduleTask(in: .milliseconds(responseTime)) {
                        let response = HTTPServerResponsePart.head(HTTPResponseHead(version: .http1_1, status: .ok))
                        let body = HTTPServerResponsePart.body(.byteBuffer(ByteBuffer(string: "OK")))
                        let end = HTTPServerResponsePart.end(nil)
                        context.write(self.wrapOutboundOut(response), promise: nil)
                        context.write(self.wrapOutboundOut(body), promise: nil)
                        context.writeAndFlush(self.wrapOutboundOut(end)).whenComplete { _ in
                            context.close(promise: nil)
                        }
                    }
                }
                else {
                    let notFoundResponse = HTTPServerResponsePart.head(HTTPResponseHead(version: .http1_1, status: .notFound))
                    let end = HTTPServerResponsePart.end(nil)
                    context.write(self.wrapOutboundOut(notFoundResponse), promise: nil)
                    context.writeAndFlush(self.wrapOutboundOut(end)).whenComplete { _ in
                        context.close(promise: nil)
                    }
                }

            case .body:
                break
            case .end:
                break
        }
    }

    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        context.close(promise: nil)
    }
}
