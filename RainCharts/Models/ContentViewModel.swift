//
//  ContentViewModel.swift
//  RainCharts
//
//  Created by David Bick on 01/01/2025.
//

import Foundation
import SwiftUI
import CoreLocation

@MainActor
class ContentViewModel: NSObject, CLLocationManagerDelegate, ObservableObject {
    private var locationManager = CLLocationManager()
    private nonisolated(unsafe) var currentRefreshTask: Task<Void, Never>?
    private nonisolated(unsafe) var debounceTask: Task<Void, Never>?
    private let forecastService: ForecastService
    private var isRefreshing = false
    private var pendingRefresh = false

    @Published var forecast: Forecast?
    @Published var errorMessage: String?
    @Published var location: CLLocation?
    @Published var forecastLog: [ForecastLog] = []

    override init() {
        self.forecastService = ForecastService()
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = 100
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    init(forecast: Forecast?, location: CLLocation?, forecastService: ForecastService = ForecastService()) {
        self.forecast = forecast
        self.location = location
        self.forecastService = forecastService
        super.init()
    }

    // Called when the location changes
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        // Truncate the location to preserve privacy, reduce redundant requests
        let approxLocation = CLLocation(
            latitude: newLocation.coordinate.latitude.rounded(to: 4),
            longitude: newLocation.coordinate.longitude.rounded(to: 4)
        )

        Task { @MainActor in
            // Only update if location actually changed
            if let currentLocation = self.location,
               currentLocation.coordinate.latitude == approxLocation.coordinate.latitude &&
               currentLocation.coordinate.longitude == approxLocation.coordinate.longitude {
                return
            }

            self.location = approxLocation

            // Debounce: cancel any pending debounce and start a new one
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }

                currentRefreshTask?.cancel()
                currentRefreshTask = Task {
                    await refreshForecast()
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Refreshes the forecast data.
    /// - Parameter immediate: If true, bypasses the isRefreshing guard by queuing a pending refresh.
    ///   Use for user-initiated refreshes (pull-to-refresh) that should not be silently dropped.
    func refreshForecast(immediate: Bool = false) async {
        // Check if already refreshing
        if isRefreshing {
            // For immediate (user-initiated) refreshes, queue a pending refresh
            if immediate {
                pendingRefresh = true
            }
            return
        }

        isRefreshing = true

        defer {
            isRefreshing = false
            // Check for pending refresh after completion
            if pendingRefresh {
                pendingRefresh = false
                Task {
                    await refreshForecast(immediate: true)
                }
            }
        }

        // Check if task was cancelled
        if Task.isCancelled {
            return
        }

        // Exit if we don't have a location
        guard let location: CLLocation = self.location else {
            self.forecast = Forecast(nextDayRainData: [], nextHourRainData: [])
            self.errorMessage = "No location available"
            return
        }

        do {
            let newForecast = try await forecastService.fetchForecast(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )

            // Check if task was cancelled before updating UI
            guard !Task.isCancelled else { return }

            self.forecast = newForecast
            self.errorMessage = nil
            self.forecastLog.append(ForecastLog(datetime: Date(), location: location))
            while self.forecastLog.count > 5 {
                self.forecastLog.removeFirst()
            }
        } catch {
            // Check if task was cancelled before updating UI
            guard !Task.isCancelled else { return }

            self.errorMessage = error.localizedDescription
        }
    }
    
    deinit {
        debounceTask?.cancel()
        currentRefreshTask?.cancel()
    }
}

extension CLLocationDegrees {
    func rounded(to decimalPlaces: Int) -> CLLocationDegrees {
        let multiplier = pow(10.0, Double(decimalPlaces))
        return (self * multiplier).rounded() / multiplier
    }
}
