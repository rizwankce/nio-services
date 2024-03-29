//
//  PingChannelHandler.swift
//
//
//  Created by Rizwan on 05/02/24.
//

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1

/// A channel handler for handling ping requests and generating ping responses.
public final class PingChannelHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    /// The `PingResponseTime` instance to track response times.
    private let pingResponseTime: PingResponseTime
    
    /// Initializes a new instance of `PingChannelHandler`.
    /// - Parameter pingResponseTime: The `PingResponseTime` instance to track response times.
    init(pingResponseTime: PingResponseTime) {
        self.pingResponseTime = pingResponseTime
    }
    
    /// Handles the read event when a request is received.
    /// generates a ping response with a random response time between 20 and 5000 milliseconds.
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = self.unwrapInboundIn(data)
        switch requestPart {
            case .head(let request):
                if request.uri.unicodeScalars.starts(with: "/ping".unicodeScalars) {
                    let responseTime = Int64.random(in: 20 ... 5000)
                    pingResponseTime.add(time: Double(responseTime))
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
    
    /// Handles the read complete event.
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
    
    /// Handles errors that occur in the channel pipeline.
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        context.close(promise: nil)
    }
}
