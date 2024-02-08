//
//  PingResponseTime.swift
//
//
//  Created by Rizwan on 05/02/24.
//

import Foundation

/// A class that represents the response time statistics for pings.
public class PingResponseTime {
    /// The start time of the statistics.
    var startTime: Date = Date()
    
    /// The number of response times.
    var count: Int = 0
    
    /// The total time of all response times.
    var totalTime: Double = 0.0
    
    /// The minimum response time.
    var minTime: Double = Double.infinity
    
    /// The maximum response time.
    var maxTime: Double = 0.0
    
    /// Adds a ping response time to the statistics.
    ///
    /// - Parameter time: The response time to add.
    func add(time: Double) {
        count += 1
        totalTime += time
        minTime = min(minTime, time)
        maxTime = max(maxTime, time)
    }
    
    /// The average response time.
    var averageTime: Double {
        totalTime / Double(count == 0 ? 1 : count)
    }
    
    /// The uptime since the start time.
    var upTime: Double {
        Date().timeIntervalSince(startTime)
    }
    
    /// Returns the statistics as a `StatsResponseModel` object.
    ///
    /// If the minimum time is still `Double.infinity`, it is set to 0.0.
    ///
    /// - Returns: The `StatsResponseModel` object representing the statistics.
    func getStatsResponseModel() -> StatsResponseModel {
        if minTime == Double.infinity {
            minTime = 0.0
        }
        return StatsResponseModel(uptime: upTime, responseTime: ResponseTime(average: averageTime, min: minTime, max: maxTime))
    }
}
