//
//  AppGroupStore.swift
//  RainCharts
//
//  Created by David Bick on 04/04/2026.
//

import Foundation

struct AppGroupStore {
    static let suiteName = "group.uk.co.drybones.raincharts"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Location

    static func saveCachedLocation(_ location: CachedLocation) {
        guard let data = try? encoder.encode(location) else { return }
        defaults?.set(data, forKey: "cachedLocation")
    }

    static func loadCachedLocation() -> CachedLocation? {
        guard let data = defaults?.data(forKey: "cachedLocation") else { return nil }
        return try? decoder.decode(CachedLocation.self, from: data)
    }

    // MARK: - Forecast

    static func saveCachedForecast(_ forecast: CachedForecast) {
        guard let data = try? encoder.encode(forecast) else { return }
        defaults?.set(data, forKey: "cachedForecast")
    }

    static func loadCachedForecast() -> CachedForecast? {
        guard let data = defaults?.data(forKey: "cachedForecast") else { return nil }
        return try? decoder.decode(CachedForecast.self, from: data)
    }
}
