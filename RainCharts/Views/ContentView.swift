//
//  ContentView.swift
//  RainCharts
//
//  Created by David Bick on 30/12/2024.
//

import SwiftUI

var forecastService: ForecastService = ForecastService()

struct ContentView: View {
    @State var errorMessage: String?
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

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .padding()
                        .multilineTextAlignment(.leading)
                }
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
                nextHourRainData: sampleHourData)
        )
    )
}
