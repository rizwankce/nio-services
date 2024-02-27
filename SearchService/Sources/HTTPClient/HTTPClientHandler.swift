//
//  HTTPClientHandler.swift
//
//
//  Created by Rizwan on 27/02/24.
//

import Foundation
import NIOSSL
import NIOCore
import NIOHTTP1
import NIOPosix

/// A custom channel inbound handler for handling HTTP client responses.
final class HTTPClientHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPClientResponsePart
    typealias OutboundOut = HTTPClientRequestPart
    
    /// The buffer to store the response.
    var buffer: ByteBuffer?
    
    /// The promise to fulfill with the response buffer.
    var responsePromise: EventLoopPromise<ByteBuffer>
    
    /// Initializes a new instance of the `HTTPClientHandler` class.
    /// - Parameter responsePromise: The promise to fulfill with the response buffer.
    init(responsePromise: EventLoopPromise<ByteBuffer>) {
        self.responsePromise = responsePromise
    }
    
    /// Called when the channel reads a new message.
    /// - Parameters:
    ///   - context: a `ChannelHandlerContext` instance.
    ///   - data: a `NIOAny` instance.
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = self.unwrapInboundIn(data)
        
        switch part {
            case .head(_):
                self.buffer = ByteBuffer()
            case .body(var body):
                if var buffer = self.buffer {
                    buffer.writeBuffer(&body)
                    self.buffer = buffer
                }
            case .end:
                if let buffer = self.buffer {
                    self.responsePromise.succeed(buffer)
                }
                context.close(promise: nil)
        }
    }
    
    /// Called when the channel reads an error.
    /// - Parameters:
    ///   - context: a `ChannelHandlerContext` instance.
    ///   - error:  an `Error` instance.
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.close(promise: nil)
        self.responsePromise.fail(error)
    }
}
