//
//  SampleRainDataPoints.swift
//  RainCharts
//
//  Created by David Bick on 30/12/2024.
//

import Foundation

var sampleHourData: [RainDataPoint] = generateHourSample()
var sampleDayData: [RainDataPoint] = generateDaySample()
var sampleBoundsData: [RainDataPoint] = generateBoundsSample()

func generateHourSample() -> [RainDataPoint] {
    let now = Date()
    let rainDataPoints = (0..<60).map { mins -> RainDataPoint in
        let prob = sin(Double(mins) * 0.03) * sin(Double(mins) * 0.03) * 0.9
        
        return RainDataPoint(
            datetime: now.addingTimeInterval(Double(mins) * 60),
            intensity: prob * Double.random(in: 0.8...1.2),
            probability: prob + Double.random(in: 0...0.1)
        )
    }
    return rainDataPoints
}

func generateDaySample() -> [RainDataPoint] {
    let now = Date()
    let rainDataPoints = (0..<24).map { hours -> RainDataPoint in
        let prob = sin(Double(hours) * 0.03) * sin(Double(hours) * 0.03) * 0.9
        
        return RainDataPoint(
            datetime: now.addingTimeInterval(Double(hours) * 60 * 60),
            intensity: prob * Double.random(in: 0.8...1.2),
            probability: prob + Double.random(in: 0...0.1)
        )
    }
    return rainDataPoints
}

func generateBoundsSample() -> [RainDataPoint] {
    let now = Date()
    var rainDataPoints: [RainDataPoint] = []
    
    rainDataPoints.append(RainDataPoint(datetime: now, intensity: 1.0, probability: 1.0))
    rainDataPoints.append(RainDataPoint(datetime: now, intensity: 1.0, probability: 0.0))
    rainDataPoints.append(RainDataPoint(datetime: now.addingTimeInterval(60*60), intensity: 1.0, probability: 1.0))
    rainDataPoints.append(RainDataPoint(datetime: now.addingTimeInterval(60*60), intensity: 1.0, probability: 0.0))
    
    return rainDataPoints
}
