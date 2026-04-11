//
//  RainChartsWidget.swift
//  RainChartsWidget
//
//  Created by David Bick on 06/04/2026.
//

import SwiftUI
import WidgetKit

struct RainEntry: TimelineEntry {
    let date: Date
    let nextHourData: [RainDataPoint]?
    let nextDayData: [RainDataPoint]?
    let locationAge: TimeInterval?
}

struct Provider: TimelineProvider {
    private let forecastService = ForecastService()

    func placeholder(in context: Context) -> RainEntry {
        RainEntry(date: Date(), nextHourData: nil, nextDayData: nil, locationAge: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RainEntry) -> Void) {
        let entry = makeEntryFromCache() ?? RainEntry(date: Date(), nextHourData: nil, nextDayData: nil, locationAge: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RainEntry>) -> Void) {
        guard let cachedLocation = AppGroupStore.loadCachedLocation() else {
            let entry = RainEntry(date: Date(), nextHourData: nil, nextDayData: nil, locationAge: nil)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
            completion(timeline)
            return
        }

        let locationAge = Date().timeIntervalSince(cachedLocation.timestamp)

        Task {
            do {
                let forecast = try await forecastService.fetchForecast(
                    latitude: cachedLocation.latitude,
                    longitude: cachedLocation.longitude
                )

                AppGroupStore.saveCachedForecast(CachedForecast(
                    nextHourRainData: forecast.nextHourRainData,
                    nextDayRainData: forecast.nextDayRainData,
                    fetchedAt: Date(),
                    latitude: cachedLocation.latitude,
                    longitude: cachedLocation.longitude
                ))

                let entries = buildSlidingTimeline(
                    nextHourData: forecast.nextHourRainData,
                    nextDayData: forecast.nextDayRainData,
                    locationAge: locationAge
                )
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            } catch {
                if let cached = AppGroupStore.loadCachedForecast(),
                   Date().timeIntervalSince(cached.fetchedAt) < 2 * 60 * 60 {
                    let entries = buildSlidingTimeline(
                        nextHourData: cached.nextHourRainData,
                        nextDayData: cached.nextDayRainData,
                        locationAge: locationAge
                    )
                    let timeline = Timeline(entries: entries, policy: .atEnd)
                    completion(timeline)
                } else {
                    let entry = RainEntry(date: Date(), nextHourData: [], nextDayData: [], locationAge: locationAge)
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
                    completion(timeline)
                }
            }
        }
    }

    // MARK: - Sliding Timeline

    private func buildSlidingTimeline(nextHourData: [RainDataPoint], nextDayData: [RainDataPoint], locationAge: TimeInterval) -> [RainEntry] {
        let now = Date()
        let intervalSeconds: TimeInterval = 5 * 60
        let windowSeconds: TimeInterval = 60 * 60

        let futureData = nextHourData.filter { $0.datetime >= now }
        guard !futureData.isEmpty, let lastPointTime = futureData.last?.datetime else {
            return [RainEntry(date: now, nextHourData: [], nextDayData: nextDayData, locationAge: locationAge)]
        }

        var entries: [RainEntry] = []
        var entryTime = now

        while entryTime < lastPointTime {
            let windowEnd = entryTime.addingTimeInterval(windowSeconds)
            let windowData = futureData.filter { $0.datetime >= entryTime && $0.datetime <= windowEnd }

            if !windowData.isEmpty {
                let updatedLocationAge = locationAge + entryTime.timeIntervalSince(now)
                entries.append(RainEntry(date: entryTime, nextHourData: windowData, nextDayData: nextDayData, locationAge: updatedLocationAge))
            }

            entryTime = entryTime.addingTimeInterval(intervalSeconds)
        }

        if entries.isEmpty {
            entries.append(RainEntry(date: now, nextHourData: [], nextDayData: nextDayData, locationAge: locationAge))
        }

        return entries
    }

    // MARK: - Cache Fallback

    private func makeEntryFromCache() -> RainEntry? {
        guard let cached = AppGroupStore.loadCachedForecast() else { return nil }
        let locationAge: TimeInterval
        if let loc = AppGroupStore.loadCachedLocation() {
            locationAge = Date().timeIntervalSince(loc.timestamp)
        } else {
            locationAge = 0
        }
        return RainEntry(date: Date(), nextHourData: cached.nextHourRainData, nextDayData: cached.nextDayRainData, locationAge: locationAge)
    }
}

// MARK: - Next Hour Widget (medium)

struct NextHourWidget: Widget {
    let kind = "NextHourWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NextHourWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rain Next Hour")
        .description("Rain probability and intensity for the next hour.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Today & Tomorrow Widget (medium)

struct TodayWidget: Widget {
    let kind = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rain Today & Tomorrow")
        .description("Rain probability and intensity for today and tomorrow.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Combined Widget (large)

struct RainChartsWidget: Widget {
    let kind = "RainChartsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CombinedWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rain Overview")
        .description("Next hour and today & tomorrow rain charts.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}
