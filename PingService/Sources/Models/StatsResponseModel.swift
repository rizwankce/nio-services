//
//  StatsResponseModel.swift
//
//
//  Created by Rizwan on 05/02/24.
//

import Foundation

/// A struct representing the statistics response model.
public struct StatsResponseModel: Codable {
    /// The average value.
    let average: Double
    
    /// The minimum value.
    let min: Double
    
    /// The maximum value.
    let max: Double
}
