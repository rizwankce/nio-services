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

/// A channel handler that handles ping requests and responses.
public final class PingChannelHandler: ChannelInboundHandler {
    
    /// The logger for the `PingChannelHandler`.
    let logger = Logger(label: "ping-channel-handler-nio")
    
    public typealias InboundIn = HTTPClientResponsePart
    public typealias OutboundOut = HTTPClientRequestPart
    
    /// The delay in milliseconds before sending a ping request.
    private let delay: Int
    
    /// The start time of the response.
    private var responseStartTime: Date?
    
    /// The object that tracks ping response times.
    private var pingResponseTime: PingResponseTime
    
    /// Initializes a new instance of `PingChannelHandler`.
    /// - Parameters:
    ///   - delay: The delay in milliseconds before sending a ping request.
    ///   - pingResponseTime: The object that tracks ping response times.
    init(delay: Int, pingResponseTime: PingResponseTime) {
        self.delay = delay
        self.responseStartTime = nil
        self.pingResponseTime = pingResponseTime
    }
    
    /// handles the active channel event.
    public func channelActive(context: ChannelHandlerContext) {
        logger.info("Client connected to \(context.remoteAddress!)")
        responseStartTime = Date()
    }
    
    /// handles the read event and calculates the response time.
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
    
    /// handles the error event.
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.info("error: \(error)")
        context.close(promise: nil)
    }
}
