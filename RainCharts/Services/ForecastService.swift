//
//  RainDataService.swift
//  RainCharts
//
//  Created by David Bick on 01/01/2025.
//

import Foundation

class ForecastService {
    let url = "https://forecast.drybones.co.uk/api/forecast?latitude=52.1389862&longitude=0.3985286"
    
    func fetchForecast() async throws -> Forecast {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime] // Include fractional seconds if needed

        let (data, _) = try await URLSession.shared.data(from: url)
        let rawJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let forcastNextDayObject = rawJSON["forecastHourly"] as? [String: Any] ?? [:]
        let forecastNextDayArray = forcastNextDayObject["hours"] as? [[String: Any]] ?? []
        let forcastNextHourObject = rawJSON["forecastNextHour"] as? [String: Any] ?? [:]
        let forecastNextHourArray = forcastNextHourObject["minutes"] as? [[String: Any]] ?? []

        let nextDayData = forecastNextDayArray.compactMap { dict -> RainDataPoint? in
            guard
                let intensity = dict["precipitationIntensity"] as? Double,
                let probablity = dict["precipitationChance"] as? Double,
                let datetimeString = dict["forecastStart"] as? String,
                let datetime = isoFormatter.date(from: datetimeString)
            else {
                return nil
            }
            return RainDataPoint(datetime: datetime, intensity: intensity, probability: probablity)
        }
        let nextHourData = forecastNextHourArray.compactMap { dict -> RainDataPoint? in
            guard
                let intensity = dict["precipitationIntensity"] as? Double,
                let probablity = dict["precipitationChance"] as? Double,
                let datetimeString = dict["startTime"] as? String,
                let datetime = isoFormatter.date(from: datetimeString)
            else {
                return nil
            }
            return RainDataPoint(datetime: datetime, intensity: intensity, probability: probablity)
        }

        return Forecast(
            nextDayRainData: nextDayData,
            nextHourRainData: nextHourData
        )
    }
    
    func fetchFakeForecast() async throws -> Forecast {
        try await Task.sleep(for: .seconds(1))
        return Forecast(nextDayRainData: generateDaySample(), nextHourRainData: generateHourSample())
    }
}

struct Forecast: Decodable {
    var nextDayRainData: [RainDataPoint]
    var nextHourRainData: [RainDataPoint]
}
