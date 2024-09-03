/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The workout manager that interfaces with HealthKit.
*/

import Foundation
import HealthKit
import CoreMotion
import SwiftUI

enum MetricType {
    case currentHeartrate
    case averageHeartRate
    case curentCadence
    case averageCadence
    case currentPace
    case averagePace
    case energy
    case distance
}

struct MetricItem: Identifiable, Hashable {
    let id = UUID()
    var value: Double
    var unit: MetricType
    var activityType: HKWorkoutActivityType
    
    var unitTitle: String {
        switch unit {
        case .currentHeartrate:
            "BPM"
        case .averageHeartRate:
            "BPM"
        case .curentCadence:
            switch activityType {
            case .running:
                "SPM"
            case .cycling:
                "RPM"
            default:
                "SPM"
            }
        case .averageCadence:
            switch activityType {
            case .running:
                "SPM"
            case .cycling:
                "RPM"
            default:
                "SPM"
            }
        case .currentPace:
            ""
        case .averagePace:
            ""
        case .energy:
            "KKAL"
        case .distance:
            "m"
        }
    }
    
    var title: String {
        switch unit {
        case .currentHeartrate:
            ""
        case .averageHeartRate:
            "AVG HR"
        case .curentCadence:
            ""
        case .averageCadence:
            ""
        case .currentPace:
            "PACE"
        case .averagePace:
            "AVG PACE"
        case .energy:
            ""
        case .distance:
            ""
        }
    }

    var icon: String? {
        switch unit {
        case .currentHeartrate:
            "heart.fill"
        case .averageHeartRate:
            nil
        case .curentCadence:
            nil
        case .averageCadence:
            nil
        case .currentPace:
            nil
        case .averagePace:
            nil
        case .energy:
            nil
        case .distance:
            nil
        }
    }
}

extension MetricItem {
    static let testMetric = MetricItem(value: 0, unit: .currentHeartrate, activityType: .running)
}

extension Collection where Element == MetricItem {
    static var testMetrics: [MetricItem] { [
        .init(value: 160, unit: .currentHeartrate, activityType: .running),
        .init(value: 175, unit: .curentCadence, activityType: .running),
        .init(value: 5, unit: .distance, activityType: .running)
    ]
    }
}

class WorkoutManager: NSObject, ObservableObject {
    private let pedometer = CMPedometer()
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }
            startWorkout(workoutType: selectedWorkout)
            setActivityType(for: selectedWorkout)
        }
    }

    @Published var showingSummaryView: Bool = false {
        didSet {
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }

    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?

    // Start the workout.
    func startWorkout(workoutType: HKWorkoutActivityType) {
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor

        // Create the session and obtain the workout builder.
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            // Handle any exceptions.
            return
        }

        // Setup session and builder.
        session?.delegate = self
        builder?.delegate = self

        // Set the workout builder's data source.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)

        // Start the workout session and begin data collection.
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
        }
        
        //Calculating cadence using pedometer
        calculateCurrentCadenceUsingPedometer()
    }
    
    private func calculateCurrentCadenceUsingPedometer() {
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] pedometerData, error in
                guard let pedometerData = pedometerData, error == nil else { return }
                
                DispatchQueue.main.async {
                    if let cadence = pedometerData.currentCadence {
                        self?.cadence.value = cadence.doubleValue * 60
                        print("Cadence updated from Pedometer data")
                    }
                }
            }
        }
    }

    // Request authorization to access HealthKit.
    func requestAuthorization() {
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKQuantityType.quantityType(forIdentifier: .runningSpeed)!,
            HKQuantityType.quantityType(forIdentifier: .cyclingSpeed)!,
            HKQuantityType.quantityType(forIdentifier: .cyclingCadence)!,
            HKObjectType.activitySummaryType()
        ]

        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
        }
    }

    // MARK: - Session State Control

    // The app's workout state.
    @Published var running = false

    func togglePause() {
        if running == true {
            self.pause()
        } else {
            resume()
        }
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func endWorkout() {
        session?.end()
        showingSummaryView = true
        pedometer.stopUpdates()
    }
    // MARK: - Workout Metrics
    @Published var averageHeartRate: MetricItem = .init(value: 0, unit: .averageHeartRate, activityType: .running)
    @Published var heartRate: MetricItem = .init(value: 0, unit: .currentHeartrate, activityType: .running)
    @Published var activeEnergy: MetricItem = .init(value: 0, unit: .energy, activityType: .running)
    @Published var distance:MetricItem = .init(value: 0, unit: .distance, activityType: .running)
    
    //New metrics
    @Published var currentPace : MetricItem = .init(value: 0, unit: .currentPace, activityType: .running)
    @Published var averagePace : MetricItem = .init(value: 0, unit: .averagePace, activityType: .running)
    @Published var cadence : MetricItem = .init(value: 0, unit: .curentCadence, activityType: .running)
    
    @Published var workout: HKWorkout?
    
    private func setActivityType(for activity: HKWorkoutActivityType) {
        averageHeartRate.activityType = activity
        heartRate.activityType = activity
        activeEnergy.activityType = activity
        distance.activityType = activity
        currentPace.activityType = activity
        averagePace.activityType = activity
        cadence.activityType = activity
    }
    

    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }

        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate.value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate.value = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.activeEnergy.value = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
                HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.distance.value = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .runningSpeed):
                let speedUnit = HKUnit.meter().unitDivided(by: HKUnit.second())
                if let speed = statistics.averageQuantity()?.doubleValue(for: speedUnit) {
                    self.averagePace.value = speed > 0 ? 1000 / (60 * speed) : 0 // Convert to min/km
                }
                if let currentSpeed = statistics.mostRecentQuantity()?.doubleValue(for: speedUnit) {
                    self.currentPace.value = currentSpeed > 0 ? 1000 / (60 * currentSpeed) : 0 // Convert to min/km
                }
            case HKQuantityType.quantityType(forIdentifier: .cyclingCadence):
                let cadenceUnit = HKUnit.count().unitDivided(by: .minute())
                self.cadence.value = statistics.averageQuantity()?.doubleValue(for: cadenceUnit) ?? 0
                self.cadence.value  *= 60
            default:
                return
            }
        }


    }

    func resetWorkout() {
        selectedWorkout = nil
        builder = nil
        workout = nil
        session = nil
        activeEnergy.value = 0
        averageHeartRate.value = 0
        heartRate.value = 0
        distance.value = 0
        
        currentPace.value = 0
        averagePace.value = 0
        cadence.value = 0
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }

        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }

            let statistics = workoutBuilder.statistics(for: quantityType)

            // Update the published values.
            updateForStatistics(statistics)
        }
    }
}

