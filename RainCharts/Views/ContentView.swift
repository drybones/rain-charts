//
//  ContentView.swift
//  RainCharts
//
//  Created by David Bick on 30/12/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Next hour")
                    .font(.title)
                
                RainChart(data: sampleHourData)
                    .padding(.bottom)
                
                Text("Today and tomorrow")
                    .font(.title)
                    .multilineTextAlignment(.leading)
                
                RainChart(data: sampleDayData)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
