//
//  MetricItemView.swift
//  MyWorkouts WatchKit App
//
//  Created by amolonus on 03/09/2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct MetricItemView: View {
    var metric: MetricItem
    var body: some View {
        Group {
            switch metric.unit {
            case .currentHeartrate:
                HStack {
                    Text(metric.value, format: .number.rounded(rule: .up, increment: 1.0))
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .symbolEffect(.bounce, options: .speed(1).repeat(20), value: metric.value)
                        .font(.system(.title3))
                    Text(" ")
                    Text(metric.title).font(.system(size: 10))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .curentCadence, .averageCadence, .averageHeartRate, .energy, .distance:
                HStack {
                    Text(metric.value, format: .number.rounded(rule: .up, increment: 1.0))
                    + Text(metric.unitTitle)
                    + Text(" ")
                    + Text(metric.title).font(.system(size: 10))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .currentPace, .averagePace:
                HStack {
                    Text(metric.value.formattedPace())
                    + Text(metric.unitTitle)
                    + Text(" ")
                    + Text(metric.title).font(.system(size: 10))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    MetricItemView(metric: .testMetric)
}
