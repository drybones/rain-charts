//
//  ContentView.swift
//  RainCharts
//
//  Created by David Bick on 30/12/2024.
//

import SwiftUI
import CoreLocation

var forecastService: ForecastService = ForecastService()

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Next hour")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                RainChart(data: viewModel.forecast?.nextHourRainData)
                    .padding(.bottom)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Today and tomorrow")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                RainChart(data: viewModel.forecast?.nextDayRainData)
                    .padding(.bottom)
                    .frame(maxWidth: .infinity, alignment: .center)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Group {
                    if let location = viewModel.location {
                        Text("Latitude: \(location.coordinate.latitude)")
                        Text("Longitude: \(location.coordinate.longitude)")
                    } else {
                        Text("Fetching location...")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .refreshable {
            await viewModel.refreshForecast()
        }
        .task {
            await viewModel.refreshForecast()
        }
    }
}

#Preview {
    ContentView(
        viewModel: ContentViewModel(
            forecast: Forecast(
                nextDayRainData: sampleDayData,
                nextHourRainData: sampleHourData),
            location: CLLocation(latitude: 40.7127, longitude: -73.9653)
        )
    )
}
