//
//  PingResponseTime.swift
//  
//
//  Created by Rizwan on 05/02/24.
//

import Foundation

public class PingResponseTime {
    var windowSize: Int = 1
    var allResponseTime: [Double] = []
    var minTime: Double = Double.infinity
    var maxTime: Double = 0.0

    func add(time: Double) {
        allResponseTime.append(time)
        minTime = min(minTime, time)
        maxTime = max(maxTime, time)
    }

    var window: [Double] {
        allResponseTime.dropLast(windowSize)
    }

    var average: Double {
        window.reduce(0.0, +) / Double(windowSize)
    }

    func getStatsResponseModel() -> StatsResponseModel {
        if minTime == Double.infinity {
            minTime = 0.0
        }
        return StatsResponseModel(average: average, min: minTime, max: maxTime)
    }
}
