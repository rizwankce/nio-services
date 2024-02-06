//
//  PingResponseTime.swift
//  
//
//  Created by Rizwan on 05/02/24.
//

import Foundation

public class PingResponseTime {
    var startTime: Date = Date()
    var count: Int = 0
    var totalTime: Double = 0.0
    var minTime: Double = Double.infinity
    var maxTime: Double = 0.0

    func add(time: Double) {
        count += 1
        totalTime += time
        minTime = min(minTime, time)
        maxTime = max(maxTime, time)
        print("After adding: \(self)")
    }

    var averageTime: Double {
        totalTime / Double(count == 0 ? 1 : count)
    }

    var upTime: Double {
        Date().timeIntervalSince(startTime)
    }

    func getStatsResponseModel() -> StatsResponseModel {
        if minTime == Double.infinity {
            minTime = 0.0
        }
        return StatsResponseModel(uptime: upTime, responseTime: ResponseTime(average: averageTime, min: minTime, max: maxTime))
    }
}
