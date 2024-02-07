//
//  File.swift
//  
//
//  Created by Rizwan on 06/02/24.
//

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1

public final class SearchChannelHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    /*
        - `updateDate` - returns the last update date of the data set
        - `numberOfObservingFacilities` - returns the number of facilities in the current data set
        - `search?name=xxx` - returns the UUIDs of all facilities with a name containing the search criteria.
        - `location?uuid=UUID` - returns the longitude and latitude (as Double values) of a facility with a given UUID.
    */

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = self.unwrapInboundIn(data)
        switch requestPart {
            case .head(let request):
                print("Received URI :\(request.uri)")
                if request.uri.starts(with: "/api/updateDate") {

                }
                else if request.uri.starts(with: "/api/numberOfObservingFacilities") {

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
                    print("Searching for name: \(searchName)")
                }
                else if request.uri.starts(with: "/api/location") {
                    let queryParameters = getQueryParameters(from: request.uri)
                    guard let locationUUID = queryParameters["uuid"] else {
                        let notFoundResponse = HTTPServerResponsePart.head(HTTPResponseHead(version: .http1_1, status: .forbidden))
                        let end = HTTPServerResponsePart.end(nil)
                        context.write(self.wrapOutboundOut(notFoundResponse), promise: nil)
                        context.writeAndFlush(self.wrapOutboundOut(end)).whenComplete { _ in
                            context.close(promise: nil)
                        }
                        return
                    }
                    print("Location for uuid: \(locationUUID)")
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

    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        context.close(promise: nil)
    }

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
