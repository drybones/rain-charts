//
//  WidgetChartView.swift
//  RainChartsWidget
//
//  Created by David Bick on 04/04/2026.
//

import SwiftUI
import Charts

struct WidgetChartView: View {
    let data: [RainDataPoint]
    let compact: Bool

    private let rainColor = Color(red: 0.486, green: 0.710, blue: 0.925, opacity: 0.5)

    var body: some View {
        Chart(data) { rainDataPoint in
            PointMark(
                x: .value("Datetime", rainDataPoint.datetime),
                y: .value("Probability", rainDataPoint.probability)
            )
            .symbolSize(rainDataPoint.intensity * (compact ? 300 : 500))
            .foregroundStyle(rainColor)
        }
        .chartXAxis {
            AxisMarks(values: generateTickValues()) {
                AxisValueLabel(format: .dateTime.hour().minute())
                    .font(.system(size: compact ? 8 : 10))
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
            }
        }
        .chartPlotStyle { plotArea in
            plotArea.padding(.bottom, compact ? 2 : 8)
        }
        .chartYScale(domain: 0...1)
        .chartYAxis {
            if compact {
                AxisMarks(position: .leading, values: [0, 0.5, 1.0]) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                }
            } else {
                AxisMarks(position: .leading) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    AxisValueLabel(format: Decimal.FormatStyle.Percent.percent)
                        .font(.system(size: 10))
                }
            }
        }
    }

    private func generateTickValues() -> [Date] {
        guard let minDate = data.map(\.datetime).min(),
              let maxDate = data.map(\.datetime).max() else {
            return []
        }

        let range = maxDate.timeIntervalSince(minDate)
        let interval: TimeInterval
        if range < 120 * 60 {
            // Minutely data (next hour): 30-min or 15-min ticks
            interval = compact ? 30 * 60 : 15 * 60
        } else {
            // Hourly data (today & tomorrow): 8-hour ticks
            interval = 8 * 60 * 60
        }

        let roundedMin = minDate.roundedUpToNearest(interval: interval)
        let roundedMax = maxDate.roundedDownToNearest(interval: interval)

        var ticks: [Date] = []
        var current = roundedMin
        while current <= roundedMax {
            ticks.append(current)
            current = current.addingTimeInterval(interval)
        }
        return ticks
    }
}
