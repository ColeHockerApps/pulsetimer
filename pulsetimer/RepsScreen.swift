//
//  RepsScreen.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public struct RepsScreen: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @StateObject private var vm = RepsViewModel()

    // Add-ons
    @State private var exercises: [Exercise] = []
    @State private var selectedExerciseId: UUID? = nil

    @State private var restSeconds: Int = 60
    @State private var isResting: Bool = false
    @State private var restRemaining: Int = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        let th = themeManager
        let topTitle = selectedExerciseName() ?? vm.title

        NavigationStack {
            ZStack {
                th.colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 1)
                        .accessibilityHidden(true)

                    List {

                        // MARK: - Exercise picker
                        Section {
                            VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                SectionHeaderView(icon: themeManager.icons.reps, title: "Exercise")
                                if exercises.isEmpty {
                                    HStack {
                                        Image(systemName: "tray")
                                            .foregroundStyle(th.colors.textSecondary)
                                        Text("No exercises in library")
                                            .foregroundStyle(th.colors.textSecondary)
                                    }
                                } else {
                                    Picker("Select", selection: Binding(
                                        get: { selectedExerciseId ?? UUID?.none as UUID?? ?? nil },
                                        set: { newId in
                                            selectedExerciseId = newId
                                            if let id = newId, let ex = exercises.first(where: { $0.id == id }) {
                                                // Prefill targets from exercise template
                                                if ex.sets.isEmpty == false {
                                                    vm.targetSets = ex.sets.count
                                                    vm.targetReps = ex.sets.first?.reps ?? vm.targetReps
                                                }
                                                haptics.tap()
                                            }
                                        }
                                    )) {
                                        ForEach(exercises) { ex in
                                            Text(ex.name).tag(Optional(ex.id))
                                        }
                                        Text("None").tag(Optional<UUID>(nil))
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Session header
                        Section {
                            VStack(spacing: 10) {
                                Text(topTitle)
                                    .font(.headline)
                                    .foregroundColor(th.colors.textPrimary)

                                HStack(spacing: 24) {
                                    ProgressDial(title: "Sets",
                                                 value: Double(vm.completedSets),
                                                 total: Double(max(1, vm.targetSets)),
                                                 main: "\(vm.completedSets)/\(vm.targetSets)")

                                    ProgressDial(title: "Reps",
                                                 value: Double(vm.currentReps),
                                                 total: Double(max(1, vm.targetReps)),
                                                 main: "\(vm.currentReps)/\(vm.targetReps)")
                                }
                                .padding(.top, 2)
                            }
                            .listRowBackground(th.colors.card)
                            .padding(.vertical, 6)
                        }

                        // MARK: - Targets
                        Section {
                            VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                SectionHeaderView(icon: "slider.horizontal.3", title: "Targets")

                                HStack {
                                    Text("Sets: \(vm.targetSets)")
                                        .foregroundStyle(th.colors.textPrimary)
                                    Spacer()
                                    Stepper("", value: $vm.targetSets, in: 1...20, step: 1)
                                        .labelsHidden()
                                        .disabled(vm.isActive && !vm.isFinished)
                                        .onChange(of: vm.targetSets) { _ in haptics.tap() }
                                }

                                HStack {
                                    Text("Reps per set: \(vm.targetReps)")
                                        .foregroundStyle(th.colors.textPrimary)
                                    Spacer()
                                    Stepper("", value: $vm.targetReps, in: 1...100, step: 1)
                                        .labelsHidden()
                                        .disabled(vm.isActive && !vm.isFinished)
                                        .onChange(of: vm.targetReps) { _ in haptics.tap() }
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Rest configuration
                        Section {
                            VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                SectionHeaderView(icon: "timer", title: "Rest")
                                HStack {
                                    Text("Rest after set: \(restSeconds)s")
                                        .foregroundStyle(th.colors.textPrimary)
                                    Spacer()
                                    Stepper("", value: $restSeconds, in: 0...300, step: 5)
                                        .labelsHidden()
                                        .disabled(vm.isFinished == false && vm.isActive == false ? false : isResting)
                                }

                                if isResting {
                                    HStack(spacing: 12) {
                                        Image(systemName: "hourglass")
                                            .foregroundStyle(th.colors.accent)
                                        Text("Resting: \(restRemaining)s")
                                            .foregroundStyle(th.colors.textPrimary)
                                        Spacer()
                                        Button("Skip") {
                                            stopRest()
                                            haptics.play(.light)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Controls
                        Section {
                            VStack(spacing: th.metrics.spacingM) {

                                if vm.isActive == false && vm.isFinished == false {
                                    PrimaryButton(title: "Start Session") {
                                        vm.startSession()
                                        haptics.confirm()
                                    }
                                } else if vm.isFinished {
                                    PrimaryButton(title: "Reset", style: .secondary) {
                                        vm.resetSession()
                                        stopRest()
                                        haptics.tap()
                                    }
                                } else {
                                    HStack(spacing: th.metrics.spacingM) {
                                        BigCircleButton(title: "-1", system: "minus", action: {
                                            guard !isResting else { return }
                                            vm.decrementRep()
                                        })
                                        BigCircleButton(title: "+1", system: "plus", action: {
                                            guard !isResting else { return }
                                            vm.incrementRep()
                                        })
                                    }
                                    .opacity(isResting ? 0.6 : 1.0)

                                    PrimaryButton(
                                        title: isResting ? "Resting..." : "Complete Set",
                                        enabled: vm.currentReps > 0 && !isResting
                                    ) {
                                        vm.completeSet()
                                        startRest()
                                    }

                                    HStack(spacing: th.metrics.spacingM) {
                                        PrimaryButton(title: "Undo Set", style: .secondary) {
                                            vm.undoSet()
                                            stopRest()
                                        }
                                        PrimaryButton(title: "Reset", style: .secondary) {
                                            vm.resetSession()
                                            stopRest()
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Summary
                        Section {
                            HStack {
                                StatChip(title: "Sets", value: "\(vm.completedSets)/\(vm.targetSets)")
                                Spacer()
                                StatChip(title: "Total Reps", value: "\(vm.totalReps)")
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(th.colors.card)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .environment(\.defaultMinListRowHeight, 10)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Reps")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { loadExercises() }
        .onReceive(timer) { _ in
            guard isResting, restRemaining > 0 else { return }
            restRemaining -= 1
            if restRemaining <= 0 { stopRest() }
        }
    }

    private func loadExercises() {
        exercises = LocalStore.shared.allExercises(sorted: true)
    }

    private func selectedExerciseName() -> String? {
        guard let id = selectedExerciseId,
              let ex = exercises.first(where: { $0.id == id }) else { return nil }
        return ex.name
    }

    private func startRest() {
        guard restSeconds > 0 else { return }
        restRemaining = restSeconds
        isResting = true
    }

    private func stopRest() {
        isResting = false
        restRemaining = 0
    }
}

// MARK: - Components

private struct ProgressDial: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let value: Double
    let total: Double
    let main: String

    var body: some View {
        let th = themeManager
        let progress = total > 0 ? min(max(value / total, 0), 1) : 0

        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(th.colors.separator.opacity(0.3), lineWidth: th.metrics.ringThickness)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(th.colors.accent, style: StrokeStyle(lineWidth: th.metrics.ringThickness, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: progress)
                Text(main)
                    .font(.headline)
                    .foregroundStyle(th.colors.textPrimary)
            }
            .frame(width: 120, height: 120)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(th.colors.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title) \(Int(value)) of \(Int(total))"))
    }
}

private struct BigCircleButton: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let system: String
    let action: () -> Void

    var body: some View {
        let th = themeManager

        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: system)
                    .font(.system(size: 20, weight: .bold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(width: 100, height: 100)
            .background(th.colors.card)
            .foregroundStyle(th.colors.textPrimary)
            .overlay(
                Circle().stroke(th.colors.separator, lineWidth: 1)
            )
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

private struct StatChip: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let value: String

    var body: some View {
        let th = themeManager
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(th.colors.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(th.colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(th.colors.card)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(th.colors.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title) \(value)"))
    }
}
