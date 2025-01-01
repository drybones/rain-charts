//
//  ContentViewModel.swift
//  RainCharts
//
//  Created by David Bick on 01/01/2025.
//

import Foundation
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var forecast: Forecast?
    @Published var errorMessage: String?
    
    init(forecast: Forecast? = nil) {
        self.forecast = forecast
    }

    func refreshForecast() async {
        do {
            let newForecast = try await forecastService.fetchForecast()
            await MainActor.run {
                self.forecast = newForecast
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
