//
//  HTTPClient.swift
//
//
//  Created by Rizwan on 27/02/24.
//

import Foundation
import NIOSSL
import NIOCore
import NIOHTTP1
import NIOPosix

/// A custom HTTP client to make requests to a server.
/// such as a REST API and supports SSL/TLS.
public final class HTTPClient {
    
    /// The event loop group to run the HTTP client on.
    private let eventLoopGroup: EventLoopGroup

    /// Initializes a new instance of the `HTTPClient` class.
    init(eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
    }

    /// Makes a GET request to the specified URL.
    func get(url: URL, eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        guard let host = url.host, let port = url.port else {
            return eventLoop.makeFailedFuture(URLError(.badURL))
        }

        do {
            let configuration = TLSConfiguration.makeClientConfiguration()
            let sslContext = try NIOSSLContext(configuration: configuration)
            let responsePromise = eventLoop.makePromise(of: ByteBuffer.self)
            let httpClientHandler = HTTPClientHandler(responsePromise: responsePromise)

            let bootstrap = ClientBootstrap(group: eventLoopGroup)
                .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
                .channelInitializer { channel in
                    let sslHandler = try! NIOSSLClientHandler(context: sslContext, serverHostname: url.host(percentEncoded: true))
                    return channel.pipeline.addHandler(sslHandler).flatMap {
                        channel.pipeline.addHTTPClientHandlers()
                    }.flatMap {
                        channel.pipeline.addHandler(httpClientHandler)
                    }
                }
            
            bootstrap.connect(host: host, port: port).whenSuccess { channel in
                var request = HTTPRequestHead(version: .http1_1, method: .GET, uri: url.path)
                request.headers.add(name: "Host", value: url.host ?? "")
                request.headers.add(name: "Accept", value: "application/json")
                channel.writeAndFlush(HTTPClientRequestPart.head(request), promise: nil)
                channel.writeAndFlush(HTTPClientRequestPart.end(nil), promise: nil)
            }

            return responsePromise.futureResult
        }
        catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
