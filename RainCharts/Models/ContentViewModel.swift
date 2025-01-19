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
    private var refreshInProgress = false

    @Published var forecast: Forecast?
    @Published var errorMessage: String?
    @Published var location: CLLocation?
    @Published var forecastLog: [ForecastLog] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = 100
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

        // Truncate the location to preserve privacy, reduce redundant requests
        let approxLocation = CLLocation(
            latitude: newLocation.coordinate.latitude.rounded(to: 4),
            longitude: newLocation.coordinate.longitude.rounded(to: 4)
        )

        self.location = approxLocation

        Task {
            await refreshForecast()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.errorMessage = error.localizedDescription
    }
    
    func refreshForecast() async {
        if(refreshInProgress) {
            return
        }
        refreshInProgress = true
        
        // Exit if we don't have a location
        guard let location: CLLocation = self.location
        else {
            await MainActor.run {
                self.forecast = Forecast(nextDayRainData: [], nextHourRainData: [])
                self.errorMessage = "No location available"
            }
            refreshInProgress = false
            return
        }
        
        do {
            let newForecast = try await forecastService.fetchForecast(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            await MainActor.run {
                self.forecast = newForecast
                self.errorMessage = nil
                self.forecastLog.append(ForecastLog(datetime: Date(), location: location))
                while self.forecastLog.count > 5 {
                    forecastLog.removeFirst()
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        refreshInProgress = false
    }
}

extension CLLocationDegrees {
    func rounded(to decimalPlaces: Int) -> CLLocationDegrees {
        let multiplier = pow(10.0, Double(decimalPlaces))
        return (self * multiplier).rounded() / multiplier
    }
}
