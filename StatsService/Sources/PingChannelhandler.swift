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

public final class PingChannelHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPClientResponsePart
    public typealias OutboundOut = HTTPClientRequestPart

    public func channelActive(context: ChannelHandlerContext) {
        print("Client connected to \(context.remoteAddress!)")
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let clientResponse = self.unwrapInboundIn(data)

        switch clientResponse {
            case .head(let responseHead):
                print("Received status: \(responseHead)")
            case .body(let byteBuffer):
                let string = String(buffer: byteBuffer)
                print("Received: '\(string)' back from the server")
            case .end:
                print("Closing channel.")
                context.close(promise: nil)
        }
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        context.close(promise: nil)
    }
}
