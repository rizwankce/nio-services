//
//  StatsResponseModel.swift
//
//
//  Created by Rizwan on 05/02/24.
//

import Foundation

/// Represents the response time statistics.
public struct ResponseTime: Codable {
    /// The average response time.
    let average: Double
    /// The minimum response time.
    let min: Double
    /// The maximum response time.
    let max: Double
}

/// Represents the statistics response model.
public struct StatsResponseModel: Codable {
    /// The uptime of the service.
    let uptime: Double
    /// The response time statistics.
    let responseTime: ResponseTime
}
