//
//  CachedForecast.swift
//  RainCharts
//
//  Created by David Bick on 04/04/2026.
//

import Foundation

struct CachedForecast: Codable {
    let nextHourRainData: [RainDataPoint]
    let nextDayRainData: [RainDataPoint]
    let fetchedAt: Date
    let latitude: Double
    let longitude: Double
}
