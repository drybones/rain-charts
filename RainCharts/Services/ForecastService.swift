//
//  RainDataService.swift
//  RainCharts
//
//  Created by David Bick on 01/01/2025.
//

import Foundation

class ForecastService {
    let baseurl = "https://forecast.drybones.co.uk/api/forecast"
    
    func fetchForecast(latitude: Double, longitude: Double) async throws -> Forecast {
        guard let baseurl = URL(string: baseurl) else {
            throw URLError(.badURL)
        }
        var urlcomponents = URLComponents(url: baseurl, resolvingAgainstBaseURL: true)
        urlcomponents?.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", latitude)), // %.4f is ~10m accuracy
            URLQueryItem(name: "longitude", value: String(format: "%.4f", longitude))
        ]
        guard let url: URL = urlcomponents?.url else {
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
