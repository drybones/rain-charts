//
//  RainDataPoint.swift
//  RainCharts
//
//  Created by David Bick on 30/12/2024.
//

import Foundation

struct RainDataPoint: Codable, Identifiable {
    let datetime: Date
    let intensity: Double
    let probability: Double
    var id: Date {
        datetime
    }
}
