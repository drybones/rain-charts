//
//  WidgetEntryView.swift
//  RainChartsWidget
//
//  Created by David Bick on 04/04/2026.
//

import SwiftUI
import WidgetKit

// MARK: - Next Hour (medium)

struct NextHourWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        if entry.locationAge == nil {
            PlaceholderViews.noLocation
        } else if let data = entry.nextHourData, !data.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Next hour")
                    .font(.headline)
                WidgetChartView(data: data, compact: true)
                LocationAgeView(age: entry.locationAge)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)
        } else if entry.nextHourData?.isEmpty == true {
            PlaceholderViews.noData
        } else {
            PlaceholderViews.loading
        }
    }
}

// MARK: - Today & Tomorrow (medium)

struct TodayWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        if entry.locationAge == nil {
            PlaceholderViews.noLocation
        } else if let data = entry.nextDayData, !data.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Today & tomorrow")
                    .font(.headline)
                WidgetChartView(data: data, compact: true)
                LocationAgeView(age: entry.locationAge)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)
        } else if entry.nextDayData?.isEmpty == true {
            PlaceholderViews.noData
        } else {
            PlaceholderViews.loading
        }
    }
}

// MARK: - Combined (large)

struct CombinedWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        if entry.locationAge == nil {
            PlaceholderViews.noLocation
        } else if entry.nextHourData != nil || entry.nextDayData != nil {
            VStack(alignment: .leading, spacing: 8) {
                if let hourData = entry.nextHourData, !hourData.isEmpty {
                    Text("Next hour")
                        .font(.headline)
                    WidgetChartView(data: hourData, compact: false)
                }

                if let dayData = entry.nextDayData, !dayData.isEmpty {
                    Text("Today & tomorrow")
                        .font(.headline)
                    WidgetChartView(data: dayData, compact: false)
                }

                LocationAgeView(age: entry.locationAge)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        } else {
            PlaceholderViews.loading
        }
    }
}

// MARK: - Shared Components

struct LocationAgeView: View {
    let age: TimeInterval?

    var body: some View {
        if let age, age > 60 * 60 {
            let hours = Int(age / 3600)
            if hours >= 1 {
                Text("Location from \(hours)h ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

enum PlaceholderViews {
    static var noLocation: some View {
        VStack(spacing: 8) {
            Image(systemName: "location.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open RainCharts to update location")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    static var noData: some View {
        VStack(spacing: 8) {
            Image(systemName: "cloud.rain")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Unable to load forecast")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    static var loading: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Loading...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
