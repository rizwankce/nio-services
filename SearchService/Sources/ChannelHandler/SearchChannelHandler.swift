//
//  SearchChannelHandler.swift
//
//
//  Created by Rizwan on 06/02/24.
//

import Foundation
import Logging
import NIOCore
import NIOPosix
import NIOHTTP1

/// A channel handler for handling search requests.
///
/// This class is responsible for processing incoming HTTP server request parts and generating HTTP server response parts.
/// It uses a `PolisDataProvider` to retrieve data for processing search requests.
public final class SearchChannelHandler: ChannelInboundHandler {
    /// The logger for the `SearchChannelHandler`.
    let logger = Logger(label: "search-channel-handler-nio")
    
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    /// The data provider for Polis data.
    private let polisDataProvider: PolisDataProvider
    
    /// initializes a new instance of `SearchChannelHandler` with the specified `PolisDataProvider`.
    /// - Parameter polisDataProvider: The data provider for Polis data.
    init(polisDataProvider: PolisDataProvider) {
        self.polisDataProvider = polisDataProvider
    }
    
    /// Handles the error by returning an internal server error response.
    func handleError(error: Error, context: ChannelHandlerContext) {
        let head = HTTPServerResponsePart.head(HTTPResponseHead(version: .http1_1, status: .internalServerError))
        var body = context.channel.allocator.buffer(capacity: 128)
        body.writeString("\(type(of: error)) error\r\n")
        let end = HTTPServerResponsePart.end(nil)
        context.write(self.wrapOutboundOut(head), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(body))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(end)).whenComplete { _ in
            context.close(promise: nil)
        }
    }
    
    /// handles the response by writing the response to the context and closing the channel.
    func handleResponse(buffer: ByteBuffer, context: ChannelHandlerContext) {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "Content-Length", value: "\(buffer.readableBytes)")
        let head = HTTPServerResponsePart.head(HTTPResponseHead(version: .http1_1, status: .ok, headers: headers))
        let end = HTTPServerResponsePart.end(nil)
        context.write(self.wrapOutboundOut(head), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(end)).whenComplete { _ in
            context.close(promise: nil)
        }
    }
    
    /// handles the read event and processes the request.
    /// support the following requests:
    /// - `updateDate` - returns the last update date of the data set
    /// - `numberOfObservingFacilities` - returns the number of facilities in the current data set
    /// - `search?name=xxx` - returns the UUIDs of all facilities with a name containing the search criteria.
    /// - `location?uuid=UUID` - returns the longitude and latitude (as Double values) of a facility with a given UUID.
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = self.unwrapInboundIn(data)
        switch requestPart {
            case .head(let request):
                logger.info("Received URI :\(request.uri)")
                if request.uri.starts(with: "/api/updateDate") {
                    polisDataProvider.getUpdatedAt(eventLoop: context.pipeline.eventLoop)
                        .whenComplete { [weak self] result in
                            switch result {
                                case .success(let success):
                                    self?.handleResponse(buffer: success, context: context)
                                case .failure(let failure):
                                    self?.handleError(error: failure, context: context)
                            }
                        }
                }
                else if request.uri.starts(with: "/api/numberOfObservingFacilities") {
                    polisDataProvider.getNumberOfObservingFacilities(eventLoop: context.pipeline.eventLoop)
                        .whenComplete { [weak self] result in
                            switch result {
                                case .success(let success):
                                    self?.handleResponse(buffer: success, context: context)
                                case .failure(let failure):
                                    self?.handleError(error: failure, context: context)
                            }
                        }
                }
                else if request.uri.starts(with: "/api/search") {
                    let queryParameters = getQueryParameters(from: request.uri)
                    guard let searchName = queryParameters["name"] else {
                        let notFoundResponse = HTTPServerResponsePart.head(HTTPResponseHead(version: .http1_1, status: .forbidden))
                        let end = HTTPServerResponsePart.end(nil)
                        context.write(self.wrapOutboundOut(notFoundResponse), promise: nil)
                        context.writeAndFlush(self.wrapOutboundOut(end)).whenComplete { _ in
                            context.close(promise: nil)
                        }
                        return
                    }
                    logger.info("Searching for name: \(searchName)")
                    polisDataProvider.getUniqueIdentifiersFor(faciltiy: searchName, eventLoop: context.pipeline.eventLoop)
                        .whenComplete { [weak self] result in
                            switch result {
                                case .success(let success):
                                    self?.handleResponse(buffer: success, context: context)
                                case .failure(let failure):
                                    self?.handleError(error: failure, context: context)
                            }
                        }
                }
                else if request.uri.starts(with: "/api/location") {
                    let queryParameters = getQueryParameters(from: request.uri)
                    guard let facilityUUID = queryParameters["uuid"],
                          let identifier = UUID(uuidString: facilityUUID) else {
                        let notFoundResponse = HTTPServerResponsePart.head(HTTPResponseHead(version: .http1_1, status: .forbidden))
                        let end = HTTPServerResponsePart.end(nil)
                        context.write(self.wrapOutboundOut(notFoundResponse), promise: nil)
                        context.writeAndFlush(self.wrapOutboundOut(end)).whenComplete { _ in
                            context.close(promise: nil)
                        }
                        return
                    }
                    logger.info("Location for uuid: \(identifier)")
                    polisDataProvider.getLocationFor(uniqueIdentifier: identifier, eventLoop: context.pipeline.eventLoop)
                        .whenComplete { [weak self] result in
                            switch result {
                                case .success(let success):
                                    self?.handleResponse(buffer: success, context: context)
                                case .failure(let failure):
                                    self?.handleError(error: failure, context: context)
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
    
    /// handles the read complete event.
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
    
    /// handles the error event.
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("error: \(error)")
        context.close(promise: nil)
    }
    
    /// handles the active channel event.
    /// - Parameter uri: The URI of the request.
    /// - Returns: a dictionary of query parameters.
    private func getQueryParameters(from uri: String) -> [String: String] {
        let queryParameters = uri.split(separator: "?").dropFirst()
        let parameters = queryParameters.reduce(into: [String: String]()) { result, query in
            let pair = query.split(separator: "=")
            if pair.count == 2 {
                result[String(pair[0])] = String(pair[1])
            }
        }
        return parameters
    }
}
