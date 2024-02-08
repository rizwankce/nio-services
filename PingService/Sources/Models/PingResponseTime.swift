//
//  PingResponseTime.swift
//
//
//  Created by Rizwan on 05/02/24.
//

import Foundation

/// A class that represents the response time statistics for pings.
public class PingResponseTime {
    /// The size of the window used for tracking response times.
    var windowSize: Int = 1
    
    /// An array of all response times.
    var allResponseTime: [Double] = []
    
    /// The minimum response time.
    var minTime: Double = Double.infinity
    
    /// The maximum response time.
    var maxTime: Double = 0.0
    
    /// Adds a response time to the statistics.
    ///
    /// - Parameter time: The response time to add.
    func add(time: Double) {
        allResponseTime.append(time)
        minTime = min(minTime, time)
        maxTime = max(maxTime, time)
    }
    
    /// The window of response times within the specified window size.
    var window: [Double] {
        allResponseTime.dropLast(windowSize)
    }
    
    /// The average response time within the window.
    var average: Double {
        window.reduce(0.0, +) / Double(windowSize)
    }
    
    /// Returns a `StatsResponseModel` object containing the statistics.
    ///
    /// If the minimum time is `Double.infinity`, it is set to 0.0.
    ///
    /// - Returns: A `StatsResponseModel` object with the average, minimum, and maximum response times.
    func getStatsResponseModel() -> StatsResponseModel {
        if minTime == Double.infinity {
            minTime = 0.0
        }
        return StatsResponseModel(average: average, min: minTime, max: maxTime)
    }
}
