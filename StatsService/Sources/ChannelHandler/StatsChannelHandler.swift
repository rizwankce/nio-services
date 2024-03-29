//
//  StatesChannelHandler.swift
//
//
//  Created by Rizwan on 05/02/24.
//

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOFoundationCompat

/// A class representing the channel handler for the stats server.
public final class StatesChannelHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    /// The `PingResponseTime` instance to track response times.
    private var pingResponseTime: PingResponseTime
    
    /// Initializes a new instance of `StatesChannelHandler`.
    init(pingResponseTime: PingResponseTime) {
        self.pingResponseTime = pingResponseTime
    }
    
    /// accepts /stats requests and returns the response time statistics.
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = self.unwrapInboundIn(data)
        switch requestPart {
            case .head(let request):
                if request.uri.unicodeScalars.starts(with: "/stats".unicodeScalars) {
                    let stats = pingResponseTime.getStatsResponseModel()
                    var buffer: ByteBuffer =  ByteBufferAllocator().buffer(capacity: 1024)
                    do {
                        try JSONEncoder().encode(stats, into: &buffer)
                        var headers = HTTPHeaders()
                        headers.add(name: "Content-Type", value: "application/json")
                        headers.add(name: "Content-Length", value: "\(buffer.readableBytes)")
                        let response = HTTPServerResponsePart.head(HTTPResponseHead(version: .http1_1, status: .ok, headers: headers))
                        let body = HTTPServerResponsePart.body(.byteBuffer(buffer))
                        let end = HTTPServerResponsePart.end(nil)
                        context.write(self.wrapOutboundOut(response), promise: nil)
                        context.write(self.wrapOutboundOut(body), promise: nil)
                        context.writeAndFlush(self.wrapOutboundOut(end)).whenComplete { _ in
                            context.close(promise: nil)
                        }
                    }
                    catch {
                        let response = HTTPServerResponsePart.head(HTTPResponseHead(version: .http1_1, status: .internalServerError))
                        let end = HTTPServerResponsePart.end(nil)
                        context.write(self.wrapOutboundOut(response), promise: nil)
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
    
    /// handle the read complete event.
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
    
    /// handle errors that occur in the channel pipeline.
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        context.close(promise: nil)
    }
}
