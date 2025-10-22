//
//  GoalsScreen.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public struct GoalsScreen: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @StateObject private var vm = GoalsViewModel()

    @State private var showAddSheet: Bool = false
    @State private var metricPicker: Bool = true
    @State private var durationH: String = "0"
    @State private var durationM: String = "30"
    @State private var distanceValue: String = "5.0"
    @State private var exercisesCount: String = "3"
    @State private var intervalsCount: String = "8"
    @State private var caloriesValue: String = "400"

    public init() {}

    public var body: some View {
        let th = themeManager

        NavigationStack {
            ZStack {
                th.colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 1)
                        .accessibilityHidden(true)

                    List {

                        // MARK: - Summary
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeaderView(icon: themeManager.icons.goals, title: "Today’s Goals")
                                HStack {
                                    ProgressRing(progress: vm.summaryPercent)
                                        .frame(width: 64, height: 64)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(Int(vm.summaryPercent * 100))% completed")
                                            .font(.headline)
                                            .foregroundStyle(th.colors.textPrimary)
                                        Text("Auto-updates from Cardio/Interval/Exercises")
                                            .font(.caption)
                                            .foregroundStyle(th.colors.textSecondary)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Quick inputs (manual counters)
                        Section {
                            VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                SectionHeaderView(icon: "slider.horizontal.3", title: "Manual Counters")

                                HStack {
                                    Text("Completed exercises")
                                        .foregroundStyle(th.colors.textPrimary)
                                    Spacer()
                                    Stepper("", value: $vm.completedExercises, in: 0...100)
                                        .labelsHidden()
                                }
                                HStack {
                                    Text("Completed intervals")
                                        .foregroundStyle(th.colors.textPrimary)
                                    Spacer()
                                    Stepper("", value: $vm.completedIntervals, in: 0...200)
                                        .labelsHidden()
                                }
                                HStack {
                                    Text("Manual calories")
                                        .foregroundStyle(th.colors.textPrimary)
                                    Spacer()
                                    TextField("0", value: $vm.manualCalories, format: .number)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 90)
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Goals list
                        Section {
                            if vm.items.isEmpty {
                                VStack(spacing: 8) {
                                    Text("No goals yet")
                                        .foregroundStyle(th.colors.textSecondary)
                                    PrimaryButton(title: "Add Quick Presets") {
                                        vm.addQuickPresets()
                                        haptics.confirm()
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 12)
                                .listRowBackground(th.colors.card)
                            } else {
                                ForEach(vm.items) { g in
                                    GoalRow(goal: g, useMetric: vm.useMetric) { newTarget in
                                        vm.updateTarget(id: g.id, newTarget: newTarget)
                                        haptics.tap()
                                    } onDelete: {
                                        vm.removeGoal(id: g.id)
                                        haptics.reject()
                                    }
                                    .listRowBackground(th.colors.card)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            vm.removeGoal(id: g.id)
                                            haptics.reject()
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .environment(\.defaultMinListRowHeight, 10)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(th.colors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        vm.addQuickPresets()
                        haptics.play(.light)
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    .accessibilityLabel("Add quick presets")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        metricPicker = vm.useMetric
                        showAddSheet = true
                        haptics.play(.medium)
                    } label: {
                        Image(systemName: themeManager.icons.add)
                    }
                    .accessibilityLabel("Add goal")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddGoalSheet(
                    useMetric: $metricPicker,
                    durationH: $durationH,
                    durationM: $durationM,
                    distanceValue: $distanceValue,
                    exercisesCount: $exercisesCount,
                    intervalsCount: $intervalsCount,
                    caloriesValue: $caloriesValue,
                    onApplyMetric: { vm.useMetric = metricPicker },
                    onAddDuration: {
                        let h = Int(durationH) ?? 0
                        let m = Int(durationM) ?? 0
                        _ = vm.addDurationGoal(hours: h, minutes: m)
                        haptics.confirm()
                    },
                    onAddDistance: {
                        let v = Double(distanceValue.replacingOccurrences(of: ",", with: ".")) ?? 0
                        vm.useMetric = metricPicker
                        _ = vm.addDistanceGoal(value: v)
                        haptics.confirm()
                    },
                    onAddExercises: {
                        let c = Int(exercisesCount) ?? 0
                        _ = vm.addExercisesGoal(count: c)
                        haptics.confirm()
                    },
                    onAddIntervals: {
                        let c = Int(intervalsCount) ?? 0
                        _ = vm.addIntervalsGoal(count: c)
                        haptics.confirm()
                    },
                    onAddCalories: {
                        let c = Int(caloriesValue) ?? 0
                        _ = vm.addCaloriesGoal(kcal: c)
                        haptics.confirm()
                    }
                )
                .presentationDetents([.medium, .large])
                .environmentObject(themeManager)
                .environmentObject(haptics)
            }
        }
    }
}

// MARK: - Goal row

private struct GoalRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let goal: DailyGoal
    let useMetric: Bool
    let onChangeTarget: (Double) -> Void
    let onDelete: () -> Void

    @State private var targetText: String = ""

    var body: some View {
        let th = themeManager

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title(goal))
                    .font(.headline)
                    .foregroundStyle(th.colors.textPrimary)
                Spacer()
                ProgressRing(progress: goal.percent)
                    .frame(width: 28, height: 28)
            }

            Text(progressText(goal))
                .font(.caption)
                .foregroundStyle(th.colors.textSecondary)

            HStack(spacing: 10) {
                Text("Target")
                    .foregroundStyle(th.colors.textSecondary)
                TextField("0", text: $targetText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                PrimaryButton(title: "Update", style: .secondary) {
                    let val = Double(targetText.replacingOccurrences(of: ",", with: ".")) ?? 0
                    onChangeTarget(val)
                }
            }
        }
        .onAppear {
            targetText = defaultTargetString(goal)
        }
        .onChange(of: goal.target) { _ in
            targetText = defaultTargetString(goal)
        }
        .contextMenu {
            Button("Delete", role: .destructive, action: onDelete)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title(goal)) \(progressText(goal))"))
    }

    private func title(_ goal: DailyGoal) -> String {
        switch goal.type {
        case .duration: return "Duration"
        case .distance: return useMetric ? "Distance (km)" : "Distance (mi)"
        case .exercises: return "Exercises"
        case .calories: return "Calories"
        case .intervals: return "Intervals"
        }
    }

    private func progressText(_ goal: DailyGoal) -> String {
        switch goal.type {
        case .duration:
            return "\(DateUtils.formatDuration(goal.progress)) / \(DateUtils.formatDuration(goal.target))"
        case .distance:
            if useMetric {
                return String(format: "%.2f / %.2f km", goal.progress, goal.target)
            } else {
                let mi = PaceCalculator.kmToMiles(goal.progress)
                let tmi = PaceCalculator.kmToMiles(goal.target)
                return String(format: "%.2f / %.2f mi", mi, tmi)
            }
        case .exercises:
            return String(format: "%.0f / %.0f", goal.progress, goal.target)
        case .calories:
            return String(format: "%.0f / %.0f kcal", goal.progress, goal.target)
        case .intervals:
            return String(format: "%.0f / %.0f", goal.progress, goal.target)
        }
    }

    private func defaultTargetString(_ goal: DailyGoal) -> String {
        switch goal.type {
        case .duration:
            return String(format: "%.0f", goal.target)
        case .distance:
            if useMetric { return String(format: "%.2f", goal.target) }
            let tmi = PaceCalculator.kmToMiles(goal.target)
            return String(format: "%.2f", tmi)
        case .exercises, .calories, .intervals:
            return String(format: "%.0f", goal.target)
        }
    }
}

// MARK: - Add sheet

private struct AddGoalSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager

    @Binding var useMetric: Bool
    @Binding var durationH: String
    @Binding var durationM: String
    @Binding var distanceValue: String
    @Binding var exercisesCount: String
    @Binding var intervalsCount: String
    @Binding var caloriesValue: String

    let onApplyMetric: () -> Void
    let onAddDuration: () -> Void
    let onAddDistance: () -> Void
    let onAddExercises: () -> Void
    let onAddIntervals: () -> Void
    let onAddCalories: () -> Void

    var body: some View {
        let th = themeManager
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Units")
                            .foregroundStyle(th.colors.textPrimary)
                        Spacer()
                        Picker("", selection: $useMetric) {
                            Text("Metric").tag(true)
                            Text("Imperial").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: useMetric) { _ in onApplyMetric() }
                    }
                }
                .listRowBackground(th.colors.card)

                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        SectionHeaderView(icon: "clock", title: "Duration")
                        HStack(spacing: 10) {
                            LabeledField(title: "h", text: $durationH, width: 70)
                            LabeledField(title: "m", text: $durationM, width: 70)
                        }
                        PrimaryButton(title: "Add Duration Goal") { onAddDuration() }
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }

                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        SectionHeaderView(icon: "ruler", title: "Distance")
                        LabeledField(title: useMetric ? "km" : "mi", text: $distanceValue, width: 120)
                        PrimaryButton(title: "Add Distance Goal") { onAddDistance() }
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }

                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        SectionHeaderView(icon: "dumbbell.fill", title: "Exercises")
                        LabeledField(title: "count", text: $exercisesCount, width: 120)
                        PrimaryButton(title: "Add Exercises Goal") { onAddExercises() }
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }

                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        SectionHeaderView(icon: "timer", title: "Intervals")
                        LabeledField(title: "count", text: $intervalsCount, width: 120)
                        PrimaryButton(title: "Add Intervals Goal") { onAddIntervals() }
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }

                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        SectionHeaderView(icon: "flame.fill", title: "Calories")
                        LabeledField(title: "kcal", text: $caloriesValue, width: 120)
                        PrimaryButton(title: "Add Calories Goal") { onAddCalories() }
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 10)
            .scrollContentBackground(.hidden)
            .background(th.colors.background.ignoresSafeArea())
            .navigationTitle("Add Goals")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Small components

private struct ProgressRing: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let progress: Double

    var body: some View {
        let th = themeManager
        ZStack {
            Circle()
                .stroke(th.colors.separator.opacity(0.3), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(th.colors.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: progress)
        }
        .accessibilityLabel(Text("Progress \(Int(progress * 100)) percent"))
    }
}

private struct LabeledField: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    @Binding var text: String
    var width: CGFloat = 90

    var body: some View {
        let th = themeManager
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(th.colors.textSecondary)
                .frame(width: 44, alignment: .leading)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: width)
        }
    }
}
