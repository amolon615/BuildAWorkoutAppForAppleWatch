/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The workout metrics view.
*/

import SwiftUI
import HealthKit

struct AdvancedMetricsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    
    private var multipleMetricsGroups: [[MetricItem]]
    private var metricsGroup: [MetricItem]
    
    private init(multipleMetricsGroups: [[MetricItem]], metricsGroup: [MetricItem]) {
        self.multipleMetricsGroups = multipleMetricsGroups
        self.metricsGroup = metricsGroup
    }
    
    // Public initializer for multipleMetricsGroups
    init(multipleMetricsGroups: [[MetricItem]]) {
        self.init(multipleMetricsGroups: multipleMetricsGroups, metricsGroup: [])
    }
    
    // Public initializer for metricsGroup
    init(metricsGroup: [MetricItem]) {
        self.init(multipleMetricsGroups: [], metricsGroup: metricsGroup)
    }

    
    var body: some View {
        TimelineView(
            MetricsTimelineSchedule(
                from: workoutManager.builder?.startDate ?? Date(),
                isPaused: workoutManager.session?.state == .paused
            )
        ) { context in
            //Time view stays on top all the time.
            VStack(alignment: .leading) {
                ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime(at: context.date) ?? 0, showSubseconds: context.cadence == .live)
                    .foregroundStyle(.yellow)
            }
            .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
            .frame(maxWidth: .infinity, alignment: .leading)
            .ignoresSafeArea(edges: .bottom)
            //Metrics pages
            metricsConfiguration
                .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    @ViewBuilder
    private var metricsConfiguration: some View {
        if metricsGroup.isEmpty && !multipleMetricsGroups.isEmpty {
            metricTabView
        } else if !metricsGroup.isEmpty && multipleMetricsGroups.isEmpty {
            metricsView(for: metricsGroup)
        }
    }
    
    
    @ViewBuilder
    private var metricTabView: some View {
        TabView {
            ForEach(multipleMetricsGroups, id:\.self) { metrics in
                metricsView(for: metrics)
                    .tag(metrics.first)
                    .padding(.top)
            }
        }
        .tabViewStyle(.verticalPage(transitionStyle: .blur))
    }
    
    
    @ViewBuilder
    private func metricsView(for metrics: [MetricItem]) -> some View {
        VStack {
            ForEach(metrics) { metric in
                MetricItemView(metric: metric)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding([.leading, .top])
    }
}

struct MetricsView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedMetricsView(metricsGroup: .testMetrics).environmentObject(WorkoutManager())
            .previewDisplayName("Metrics Group Preview")
        AdvancedMetricsView(metricsGroup: [.testMetric, .testMetric]).environmentObject(WorkoutManager())
            .previewDisplayName("Multiple Metrics Group Preview")
    }
}

private struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
    var isPaused: Bool

    init(from startDate: Date, isPaused: Bool) {
        self.startDate = startDate
        self.isPaused = isPaused
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var baseSchedule = PeriodicTimelineSchedule(from: self.startDate,
                                                    by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0))
            .entries(from: startDate, mode: mode)
        
        return AnyIterator<Date> {
            guard !isPaused else { return nil }
            return baseSchedule.next()
        }
    }
}
