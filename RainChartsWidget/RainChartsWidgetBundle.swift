//
//  RainChartsWidgetBundle.swift
//  RainChartsWidget
//
//  Created by David Bick on 06/04/2026.
//

import SwiftUI
import WidgetKit

@main
struct RainChartsWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextHourWidget()
        TodayWidget()
        RainChartsWidget()
    }
}
