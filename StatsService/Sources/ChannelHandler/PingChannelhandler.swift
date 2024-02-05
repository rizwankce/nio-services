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

    private let delay: Int
    private var responseStartTime: Date?
    private var pingResponseTime: PingResponseTime

    init(delay: Int, pingResponseTime: PingResponseTime) {
        self.delay = delay
        self.responseStartTime = nil
        self.pingResponseTime = pingResponseTime
    }

    public func channelActive(context: ChannelHandlerContext) {
        print("Client connected to \(context.remoteAddress!)")
        responseStartTime = Date()
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        print("client Channel Read")
        let clientResponse = self.unwrapInboundIn(data)

        switch clientResponse {
            case .head(let responseHead):
                print("Received status: \(responseHead)")
                if let startTime = responseStartTime {
                    let responseTime = Date().timeIntervalSince(startTime)
                    print("Response time: \(responseTime)")
                    responseStartTime = nil
                    pingResponseTime.add(time: responseTime)
                }
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
