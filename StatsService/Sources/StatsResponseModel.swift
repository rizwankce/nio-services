//
//  File.swift
//  
//
//  Created by Rizwan on 05/02/24.
//

import Foundation

public struct ResponseTime: Codable {
    let average: Int
    let min: Int
    let max: Int
}

public struct StatsResponseModel: Codable {
    let uptime: Int
    let responseTime: ResponseTime
}
