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
    
    let data: [RainDataPoint]?
    let rainColor = Color(red: 0.486, green: 0.710, blue: 0.925, opacity: 0.5)

    var body: some View {
        Group {
            if let data = data {
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
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine()
                        AxisTick(length: 12, stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.background) // Fake padding to match the symbol size
                        AxisValueLabel(format: Decimal.FormatStyle.Percent.percent)
                    }
                }
                .padding()
                .frame(height: 200)
            } else {
                ProgressView("Loading...")
                    .padding(.trailing)
                    .frame(height: 200)
            }
        }
    }
    
    // Generate rounded tick values based on the dataset
    func generateRoundedTickValues(data: [RainDataPoint]) -> [Date] {
        guard let minDate = data.map(\.datetime).min(),
              let maxDate = data.map(\.datetime).max() else {
            return []
        }
        
        let range = maxDate.timeIntervalSince(minDate)
        let interval: TimeInterval = if range < (120 * 60) { // Minutely data is between and hour and 2 hours?
            30 * 60  // 15 mins
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

#Preview("Sample data") {
    Group {
        RainChart(data: sampleHourData)
        RainChart(data: sampleDayData)
        Spacer()
    }
}

#Preview("Bounds") {
    RainChart(data: sampleBoundsData)
}

#Preview("nil") {
    RainChart(data: nil)
}
