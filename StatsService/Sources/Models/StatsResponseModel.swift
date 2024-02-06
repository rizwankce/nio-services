//
//  StatsResponseModel.swift
//  
//
//  Created by Rizwan on 05/02/24.
//

import Foundation

public struct ResponseTime: Codable {
    let average: Double
    let min: Double
    let max: Double
}

public struct StatsResponseModel: Codable {
    let uptime: Double
    let responseTime: ResponseTime
}
