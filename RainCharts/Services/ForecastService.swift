//
//  RainDataService.swift
//  RainCharts
//
//  Created by David Bick on 01/01/2025.
//

import Foundation

class ForecastService {
    func fetchForecast() async throws -> Forecast {
        try await Task.sleep(for: .seconds(1))
        return Forecast(nextDayRainData: generateDaySample(), nextHourRainData: generateHourSample())
    }
}

struct Forecast {
    var nextDayRainData: [RainDataPoint]
    var nextHourRainData: [RainDataPoint]
}
