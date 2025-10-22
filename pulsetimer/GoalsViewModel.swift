//
//  GoalsViewModel.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation


public final class GoalsViewModel: ObservableObject {

    // MARK: - Public output

    @Published public private(set) var items: [DailyGoal] = []        // today's goals sorted by type
    @Published public private(set) var summaryPercent: Double = 0      // average completion 0...1

    // MARK: - Inputs affecting computed progress

    /// Completed interval cycles today (from Interval screen).
    @Published public var completedIntervals: Int = 0 {
        didSet { recalcProgress() }
    }

    /// Completed exercises count today (from Exercises screen).
    @Published public var completedExercises: Int = 0 {
        didSet { recalcProgress() }
    }

    /// Manual calories typed by the user.
    @Published public var manualCalories: Double = 0 {
        didSet { recalcProgress() }
    }

    // MARK: - Settings bridge

    /// true = metric (km), false = imperial (miles); used when creating/updating distance goal.
    @Published public var useMetric: Bool = true

    // MARK: - Internals

    private let store: LocalStore
    private var bag = Set<AnyCancellable>()
    private var todayKey: Date { DateUtils.startOfDay(Date()) }

    public init(store: LocalStore = .shared) {
        self.store = store
        bind()
        reload()
        recalcProgress()
    }

    // MARK: - Public API (CRUD)

    @discardableResult
    public func addDurationGoal(hours: Int = 0, minutes: Int = 30) -> DailyGoal {
        let sec = Double(max(0, hours) * 3600 + max(0, minutes) * 60)
        let g = DailyGoal(date: todayKey, type: .duration, target: sec, progress: 0)
        store.upsert(g)
        reload()
        return g
    }

    @discardableResult
    public func addDistanceGoal(value: Double) -> DailyGoal {
        // Interpret `value` according to current units; convert to km for storage.
        let km = useMetric ? max(0, value) : PaceCalculator.milesToKm(max(0, value))
        let g = DailyGoal(date: todayKey, type: .distance, target: km, progress: 0)
        store.upsert(g)
        reload()
        return g
    }

    @discardableResult
    public func addExercisesGoal(count: Int = 3) -> DailyGoal {
        let g = DailyGoal(date: todayKey, type: .exercises, target: Double(max(0, count)), progress: 0)
        store.upsert(g)
        reload()
        return g
    }

    @discardableResult
    public func addCaloriesGoal(kcal: Int = 400) -> DailyGoal {
        let g = DailyGoal(date: todayKey, type: .calories, target: Double(max(0, kcal)), progress: 0)
        store.upsert(g)
        reload()
        return g
    }

    @discardableResult
    public func addIntervalsGoal(count: Int = 8) -> DailyGoal {
        let g = DailyGoal(date: todayKey, type: .intervals, target: Double(max(0, count)), progress: 0)
        store.upsert(g)
        reload()
        return g
    }

    public func removeGoal(id: UUID) {
        store.removeGoal(id: id)
        reload()
    }

    public func updateTarget(id: UUID, newTarget: Double) {
        guard var g = store.goals[id] else { return }
        g.target = max(0, newTarget)
        store.upsert(g)
        reload()
        recalcProgress()
    }

    // MARK: - Quick presets

    public func addQuickPresets() {
        // Add a small default bundle if not present today
        if !items.contains(where: { $0.type == .duration }) { _ = addDurationGoal(hours: 0, minutes: 30) }
        if !items.contains(where: { $0.type == .distance }) { _ = addDistanceGoal(value: useMetric ? 5.0 : 3.0) }
        if !items.contains(where: { $0.type == .exercises }) { _ = addExercisesGoal(count: 3) }
        if !items.contains(where: { $0.type == .intervals }) { _ = addIntervalsGoal(count: 8) }
    }

    // MARK: - Manual progress helpers

    public func incrementExercises(by delta: Int = 1) {
        completedExercises = max(0, completedExercises + delta)
    }

    public func incrementIntervals(by delta: Int = 1) {
        completedIntervals = max(0, completedIntervals + delta)
    }

    public func setManualCalories(_ kcal: Double) {
        manualCalories = max(0, kcal)
    }

    // MARK: - Reload and compute

    public func reload() {
        // Only today's goals
        items = store.allGoals(for: todayKey)
            .filter { DateUtils.startOfDay($0.date) == todayKey }
            .sorted { a, b in
                // Deterministic order: duration, distance, exercises, intervals, calories
                orderIndex(a.type) < orderIndex(b.type)
            }
        recalcProgress()
    }

    public func recalcProgress() {
        let logsToday = store.allCardioLogs().filter { DateUtils.startOfDay($0.date) == todayKey }
        let inputs = GoalCalculator.Inputs(
            date: todayKey,
            cardio: logsToday,
            completedIntervals: completedIntervals,
            completedExercises: completedExercises,
            manualCalories: manualCalories
        )
        var updated: [DailyGoal] = []
        for g in items {
            let newG = GoalCalculator.updatedGoal(g, with: inputs)
            updated.append(newG)
            store.upsert(newG)
        }
        items = updated

        if items.isEmpty {
            summaryPercent = 0
        } else {
            let total = items.map { $0.percent }.reduce(0, +)
            summaryPercent = total / Double(items.count)
        }
    }

    // MARK: - Formatting

    public func title(for goal: DailyGoal) -> String {
        switch goal.type {
        case .duration:
            return "Duration"
        case .distance:
            return useMetric ? "Distance (km)" : "Distance (mi)"
        case .exercises:
            return "Exercises"
        case .calories:
            return "Calories"
        case .intervals:
            return "Intervals"
        }
    }

    public func progressLabel(for goal: DailyGoal) -> String {
        switch goal.type {
        case .duration:
            let progress = DateUtils.formatDuration(goal.progress)
            let target = DateUtils.formatDuration(goal.target)
            return "\(progress) / \(target)"
        case .distance:
            let km = goal.progress
            if useMetric {
                return String(format: "%.2f / %.2f km", km, goal.target)
            } else {
                let mi = PaceCalculator.kmToMiles(km)
                let targetMi = PaceCalculator.kmToMiles(goal.target)
                return String(format: "%.2f / %.2f mi", mi, targetMi)
            }
        case .exercises:
            return String(format: "%.0f / %.0f", goal.progress, goal.target)
        case .calories:
            return String(format: "%.0f / %.0f kcal", goal.progress, goal.target)
        case .intervals:
            return String(format: "%.0f / %.0f", goal.progress, goal.target)
        }
    }

    // MARK: - Bind

    private func bind() {
        store.$goals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &bag)

        store.$cardioLogs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recalcProgress() }
            .store(in: &bag)
    }

    // MARK: - Helpers

    private func orderIndex(_ type: DailyGoal.GoalType) -> Int {
        switch type {
        case .duration: return 0
        case .distance: return 1
        case .exercises: return 2
        case .intervals: return 3
        case .calories: return 4
        }
    }
}
