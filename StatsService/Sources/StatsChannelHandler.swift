//
//  File.swift
//  
//
//  Created by Rizwan on 05/02/24.
//

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOFoundationCompat

public final class StatesChannelHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = self.unwrapInboundIn(data)
        switch requestPart {
            case .head(let request):
                if request.uri.unicodeScalars.starts(with: "/stats".unicodeScalars) {
                    let stats = StatsResponseModel(uptime: 1000, responseTime: ResponseTime(average: 100, min: 0, max: 1000))
                    var buffer: ByteBuffer =  ByteBufferAllocator().buffer(capacity: 1024)
                    do {
                        try JSONEncoder().encode(stats, into: &buffer)
                        let headers = HTTPHeaders([("Content-Type", "application/json")])
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
                        // TODO: - Handle Error case
                    }
                }
                else {
                    let notFoundResponse = HTTPServerResponsePart.head(HTTPResponseHead(version: request.version, status: .notFound))
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
