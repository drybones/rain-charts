//
//  ForecastLog.swift
//  RainCharts
//
//  Created by David Bick on 19/01/2025.
//

import Foundation
import CoreLocation

struct ForecastLog: Identifiable {
    let datetime: Date
    let location: CLLocation
    var id: Date {
        datetime
    }
}
