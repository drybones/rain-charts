//
//  ContentViewModel.swift
//  RainCharts
//
//  Created by David Bick on 01/01/2025.
//

import Foundation
import SwiftUI
import CoreLocation

class ContentViewModel: NSObject, CLLocationManagerDelegate, ObservableObject {
    private var locationManager = CLLocationManager()

    @Published var forecast: Forecast?
    @Published var errorMessage: String?
    @Published var location: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    init(forecast: Forecast?, location: CLLocation?) {
        self.forecast = forecast
        self.location = location
    }

    // Called when the location changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        // Update the @Published location property
        DispatchQueue.main.async {
            self.location = newLocation
            self.handleLocationChange(newLocation) // Trigger the function when location changes
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }

    private func handleLocationChange(_ location: CLLocation) {
        Task {
            await refreshForecast()
        }
    }
    
    func refreshForecast() async {
        guard let location: CLLocation = self.location
        else {
            self.forecast = Forecast(nextDayRainData: [], nextHourRainData: [])
            return
        }
        
        do {
            let newForecast = try await forecastService.fetchForecast(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
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
