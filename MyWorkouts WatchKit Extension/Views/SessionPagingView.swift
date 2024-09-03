/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The paging view to switch between controls, metrics, and now playing views.
*/

import SwiftUI
import WatchKit

struct SessionPagingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var selection: Tab = .metrics

    enum Tab {
        case controls, metrics, secondaryMetrics, combinedMetrics, nowPlaying
    }

    var body: some View {
        TabView(selection: $selection) {
            ControlsView().tag(Tab.controls)
            metricsView.tag(Tab.metrics)
            secondaryMetricsView.tag(Tab.secondaryMetrics)
            combinedMetricsView.tag(Tab.combinedMetrics)
            NowPlayingView().tag(Tab.nowPlaying)
        }
        .navigationTitle(workoutManager.selectedWorkout?.name ?? "")
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(selection == .nowPlaying)
        .onChange(of: workoutManager.running) { _ in
            displayMetricsView()
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: isLuminanceReduced ? .never : .automatic))
        .onChange(of: isLuminanceReduced) { _ in
            displayMetricsView()
        }
    }

    private func displayMetricsView() {
        withAnimation {
            selection = .metrics
        }
    }
    
    @ViewBuilder
    private var metricsView: some View {
        let metricsToDisplay: [MetricItem] =
        [
            workoutManager.heartRate,
            workoutManager.activeEnergy,
            workoutManager.distance
        ]
        AdvancedMetricsView(metricsGroup: metricsToDisplay)
    }
    
    @ViewBuilder
    private var secondaryMetricsView: some View {
        let metricsToDisplay: [MetricItem] =
        [
            workoutManager.cadence,
            workoutManager.currentPace,
            workoutManager.averagePace
        ]
        
        AdvancedMetricsView(metricsGroup: metricsToDisplay)
    }
    
    @ViewBuilder
    private var combinedMetricsView: some View {
        let metricsToDisplay: [[MetricItem]] = [
            [
                workoutManager.heartRate,
                workoutManager.activeEnergy,
                workoutManager.activeEnergy
            ],
            [
                workoutManager.cadence,
                workoutManager.currentPace,
                workoutManager.averagePace
            ]
        ]
        
        AdvancedMetricsView(multipleMetricsGroups: metricsToDisplay)
    }
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        SessionPagingView().environmentObject(WorkoutManager())
    }
}


