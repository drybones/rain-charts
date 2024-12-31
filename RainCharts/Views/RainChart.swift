//
//  RainChart.swift
//  RainCharts
//
//  Created by David Bick on 30/12/2024.
//

import SwiftUI
import Charts
import Foundation

struct RainChart: View {
    
    let data: [RainDataPoint]
    let rainColor = Color(red: 0.486, green: 0.710, blue: 0.925, opacity: 0.5)

    var body: some View {
        Chart(data) { rainDataPoint in
            PointMark(
                x: .value("Datetime", rainDataPoint.datetime),
                y: .value("Probability", rainDataPoint.probability)
            )
            .symbolSize(rainDataPoint.intensity * 500)
            .foregroundStyle(rainColor)
        }
        .chartXAxis {
            AxisMarks(values: generateRoundedTickValues(data: data)) {
                AxisValueLabel(format: .dateTime.hour().minute())
                AxisGridLine()
            }
        }
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisValueLabel(format: Decimal.FormatStyle.Percent())
                AxisGridLine()
            }
        }
        .padding(.trailing)
        .frame(height: 200)
    }
    
    // Generate rounded tick values based on the dataset
    func generateRoundedTickValues(data: [RainDataPoint]) -> [Date] {
        guard let minDate = data.map(\.datetime).min(),
              let maxDate = data.map(\.datetime).max() else {
            return []
        }
        
        let range = maxDate.timeIntervalSince(minDate)
        let interval: TimeInterval = if range < (70 * 60) { // Wiggle room on 1 hour data
            15 * 60  // 15 mins
        } else {
            8 * 60 * 60 // 8 hours
        }
        
        // Round min and max to the nearest interval
        let roundedMin = minDate.roundedUpToNearest(interval: interval)
        let roundedMax = maxDate.roundedDownToNearest(interval: interval)
        
        // Generate ticks at the specified interval
        var ticks: [Date] = []
        var current = roundedMin
        while current <= roundedMax {
            ticks.append(current)
            current = current.addingTimeInterval(interval)
        }
        return ticks
    }
}

extension Date {
    /// Rounds the date to the nearest interval
    func roundedDownToNearest(interval: TimeInterval) -> Date {
        let timeInterval = timeIntervalSinceReferenceDate
        let roundedInterval = floor(timeInterval / interval) * interval
        return Date(timeIntervalSinceReferenceDate: roundedInterval)
    }
    func roundedUpToNearest(interval: TimeInterval) -> Date {
        let timeInterval = timeIntervalSinceReferenceDate
        let roundedInterval = ceil(timeInterval / interval) * interval
        return Date(timeIntervalSinceReferenceDate: roundedInterval)
    }
}

#Preview {
    Group {
        RainChart(data: sampleHourData)
        RainChart(data: sampleDayData)
        RainChart(data: sampleBoundsData)
    }
}
