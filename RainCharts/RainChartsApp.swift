//
//  RainChartsApp.swift
//  RainCharts
//
//  Created by David Bick on 30/12/2024.
//

import SwiftUI
import CoreLocation

@main
struct RainChartsApp: App {
    var body: some Scene {
        WindowGroup {
            #if USE_SAMPLE_DATA
            ContentView(
                viewModel: ContentViewModel(
                    forecast: Forecast(
                        nextDayRainData: sampleDayData,
                        nextHourRainData: sampleHourData
                    ),
                    location: CLLocation(latitude: 51.5074, longitude: -0.1278)
                )
            )
            #else
            ContentView()
            #endif
        }
    }
}
