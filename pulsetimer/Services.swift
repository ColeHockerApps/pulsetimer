//
//  Services.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

// MARK: - TimerEngine


public final class TimerEngine: ObservableObject {

    public enum Phase: String, Codable, Equatable {
        case work
        case rest
    }

    public enum Status: String, Codable, Equatable {
        case idle
        case running
        case paused
        case finished
    }

    public struct Config: Equatable {
        public var workSec: TimeInterval
        public var restSec: TimeInterval
        public var cycles: Int

        public init(workSec: TimeInterval, restSec: TimeInterval, cycles: Int) {
            self.workSec = max(1, workSec)
            self.restSec = max(0, restSec)
            self.cycles = max(1, cycles)
        }

        public var totalPlannedSec: TimeInterval {
            // Work for each cycle + rest between cycles (no rest after last work)
            let totalWork = workSec * Double(cycles)
            let totalRest = restSec * Double(max(0, cycles - 1))
            return totalWork + totalRest
        }
    }

    @Published public private(set) var status: Status = .idle
    @Published public private(set) var phase: Phase = .work
    @Published public private(set) var currentCycle: Int = 0 // 1-based
    @Published public private(set) var remainingSec: TimeInterval = 0
    @Published public private(set) var elapsedSec: TimeInterval = 0
    @Published public private(set) var phaseProgress: Double = 0 // 0...1
    @Published public private(set) var totalProgress: Double = 0 // 0...1

    public private(set) var config: Config = .init(workSec: 30, restSec: 15, cycles: 8)

    private var timer: DispatchSourceTimer?
    private var phaseEndDate: Date?
    private var phaseDuration: TimeInterval = 0
    private var totalElapsedBeforePhase: TimeInterval = 0

    public init() {}

    // MARK: - Control

    public func start(_ cfg: Config) {
        stopTimer()
        config = cfg
        status = .running
        phase = .work
        currentCycle = 1
        totalElapsedBeforePhase = 0
        startPhase(duration: config.workSec)
    }

    public func pause() {
        guard status == .running else { return }
        status = .paused
        captureRemaining()
        stopTimer()
    }

    public func resume() {
        guard status == .paused else { return }
        status = .running
        startPhase(duration: remainingSec) // continue current phase with remaining
    }

    public func reset() {
        stopTimer()
        status = .idle
        phase = .work
        currentCycle = 0
        remainingSec = 0
        elapsedSec = 0
        phaseProgress = 0
        totalProgress = 0
        phaseEndDate = nil
        phaseDuration = 0
        totalElapsedBeforePhase = 0
    }

    // MARK: - Internals

    private func startPhase(duration: TimeInterval) {
        phaseDuration = max(0.01, duration)
        phaseEndDate = Date().addingTimeInterval(phaseDuration)
        startTimer()
        tick() // immediate update
    }

    private func finishPhase() {
        totalElapsedBeforePhase += phaseDuration
        switch phase {
        case .work:
            if currentCycle < config.cycles, config.restSec > 0 {
                phase = .rest
                startPhase(duration: config.restSec)
            } else if currentCycle < config.cycles, config.restSec == 0 {
                // skip rest; move straight to next work
                currentCycle += 1
                phase = .work
                startPhase(duration: config.workSec)
            } else {
                // last work finished
                completeAll()
            }
        case .rest:
            // move to next cycle's work
            currentCycle += 1
            if currentCycle <= config.cycles {
                phase = .work
                startPhase(duration: config.workSec)
            } else {
                completeAll()
            }
        }
    }

    private func completeAll() {
        stopTimer()
        phaseEndDate = nil
        status = .finished
        remainingSec = 0
        elapsedSec = config.totalPlannedSec
        phaseProgress = 1
        totalProgress = 1
    }

    private func captureRemaining() {
        guard let end = phaseEndDate else { return }
        remainingSec = max(0, end.timeIntervalSince(Date()))
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        t.schedule(deadline: .now(), repeating: .milliseconds(100), leeway: .milliseconds(10))
        t.setEventHandler { [weak self] in
            self?.tick()
        }
        t.resume()
        timer = t
    }

    private func stopTimer() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        guard status == .running, let end = phaseEndDate else { return }
        let now = Date()
        let remaining = max(0, end.timeIntervalSince(now))
        remainingSec = remaining

        let elapsedInPhase = max(0, phaseDuration - remaining)
        elapsedSec = min(config.totalPlannedSec, totalElapsedBeforePhase + elapsedInPhase)

        phaseProgress = min(1, max(0, elapsedInPhase / max(0.0001, phaseDuration)))

        let total = config.totalPlannedSec
        totalProgress = total > 0 ? min(1, max(0, elapsedSec / total)) : 0

        if remaining <= 0.0001 {
            finishPhase()
        }
    }
}

// MARK: - GoalCalculator

public enum GoalCalculator {

    public struct Inputs {
        public var date: Date
        public var cardio: [CardioLog]
        public var completedIntervals: Int
        public var completedExercises: Int
        public var manualCalories: Double

        public init(
            date: Date,
            cardio: [CardioLog] = [],
            completedIntervals: Int = 0,
            completedExercises: Int = 0,
            manualCalories: Double = 0
        ) {
            self.date = DateUtils.startOfDay(date)
            self.cardio = cardio
            self.completedIntervals = max(0, completedIntervals)
            self.completedExercises = max(0, completedExercises)
            self.manualCalories = max(0, manualCalories)
        }
    }

    public static func progressValue(for goal: DailyGoal, with inputs: Inputs) -> Double {
        let day = DateUtils.startOfDay(goal.date)
        switch goal.type {
        case .duration:
            let sec = totalDuration(for: day, cardio: inputs.cardio)
            return sec
        case .distance:
            let km = totalDistance(for: day, cardio: inputs.cardio)
            return km
        case .exercises:
            return Double(inputs.completedExercises)
        case .calories:
            return inputs.manualCalories
        case .intervals:
            return Double(inputs.completedIntervals)
        }
    }

    public static func updatedGoal(_ goal: DailyGoal, with inputs: Inputs) -> DailyGoal {
        var g = goal
        g.progress = progressValue(for: goal, with: inputs)
        return g
    }

    private static func totalDuration(for day: Date, cardio: [CardioLog]) -> Double {
        let key = DateUtils.startOfDay(day)
        return cardio.filter { DateUtils.startOfDay($0.date) == key }
            .map { $0.durationSec }
            .reduce(0, +)
    }

    private static func totalDistance(for day: Date, cardio: [CardioLog]) -> Double {
        let key = DateUtils.startOfDay(day)
        return cardio.filter { DateUtils.startOfDay($0.date) == key }
            .map { $0.distanceKm }
            .reduce(0, +)
    }
}

// MARK: - PaceCalculator

public enum PaceCalculator {

    public static func kmToMiles(_ km: Double) -> Double {
        km * 0.621371192
    }

    public static func milesToKm(_ miles: Double) -> Double {
        miles / 0.621371192
    }

    /// Returns pace in seconds per kilometer.
    public static func paceSecPerKm(distanceKm: Double, durationSec: Double) -> Double {
        guard distanceKm > 0, durationSec > 0 else { return 0 }
        return durationSec / distanceKm
    }

    /// Returns speed in km/h.
    public static func speedKmPerHour(distanceKm: Double, durationSec: Double) -> Double {
        guard durationSec > 0 else { return 0 }
        return distanceKm / (durationSec / 3600.0)
    }

    /// Formats pace as "m:ss /km".
    public static func formatPace(secPerKm: Double) -> String {
        guard secPerKm > 0 else { return "--:-- /km" }
        let m = Int(secPerKm / 60)
        let s = Int(secPerKm.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d /km", m, s)
    }

    /// Formats speed as "x.x km/h".
    public static func formatSpeed(kmPerHour: Double) -> String {
        guard kmPerHour > 0 else { return "-- km/h" }
        return String(format: "%.1f km/h", kmPerHour)
    }
}
