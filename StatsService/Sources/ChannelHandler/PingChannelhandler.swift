//
//  PingChannelHandler.swift
//  
//
//  Created by Rizwan on 05/02/24.
//

import Foundation
import Logging
import NIOCore
import NIOPosix
import NIOHTTP1

public final class PingChannelHandler: ChannelInboundHandler {
    let logger = Logger(label: "ping-channel-handler-nio")
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
        logger.info("Client connected to \(context.remoteAddress!)")
        responseStartTime = Date()
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        logger.info("client Channel Read")
        let clientResponse = self.unwrapInboundIn(data)

        switch clientResponse {
            case .head(let responseHead):
                logger.info("Received status: \(responseHead)")
                if let startTime = responseStartTime {
                    let responseTime = Date().timeIntervalSince(startTime)
                    logger.info("Response time: \(responseTime)")
                    responseStartTime = nil
                    pingResponseTime.add(time: responseTime)
                }
            case .body(let byteBuffer):
                let string = String(buffer: byteBuffer)
                logger.info("Received: '\(string)' back from the server")
            case .end:
                logger.info("Closing channel.")
                context.close(promise: nil)
        }
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.info("error: \(error)")
        context.close(promise: nil)
    }
}
