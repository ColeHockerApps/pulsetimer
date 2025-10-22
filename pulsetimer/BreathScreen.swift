//
//  BreathScreen.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public struct BreathScreen: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @StateObject private var vm = BreathViewModel()

    @State private var selectedPreset: Preset = .box

    private enum Preset: String, CaseIterable, Identifiable {
        case box = "Box"
        case fourSevenEight = "4-7-8"
        case custom = "Custom"
        var id: String { rawValue }
    }

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
                        // MARK: - Header + progress
                        Section {
                            VStack(spacing: 10) {
                                Text(vm.phaseLabel)
                                    .font(.headline)
                                    .foregroundStyle(th.colors.accent)

                                ZStack {
                                    Circle()
                                        .stroke(th.colors.separator.opacity(0.3), lineWidth: th.metrics.ringThickness)
                                    Circle()
                                        .trim(from: 0, to: vm.totalProgress)
                                        .stroke(th.colors.accent, style: StrokeStyle(lineWidth: th.metrics.ringThickness, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                        .animation(.easeInOut(duration: 0.2), value: vm.totalProgress)

                                    VStack(spacing: 2) {
                                        Text(vm.remainingLabel)
                                            .font(.system(size: 42, weight: .bold, design: .rounded))
                                            .foregroundStyle(th.colors.textPrimary)
                                        Text("Cycle \(vm.cycleIndex) / \(vm.config.cycles)")
                                            .font(.subheadline)
                                            .foregroundStyle(th.colors.textSecondary)
                                    }
                                }
                                .frame(width: 180, height: 180)
                                .padding(.top, 4)

                                Text("Planned: \(vm.totalPlannedLabel)")
                                    .font(.footnote)
                                    .foregroundStyle(th.colors.textSecondary)
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Presets
                        Section {
                            VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                SectionHeaderView(icon: themeManager.icons.breath, title: "Presets")

                                HStack(spacing: th.metrics.spacingM) {
                                    PresetChip(title: "Box", selected: selectedPreset == .box) {
                                        selectedPreset = .box
                                        vm.config = .box
                                        haptics.tap()
                                    }
                                    PresetChip(title: "4-7-8", selected: selectedPreset == .fourSevenEight) {
                                        selectedPreset = .fourSevenEight
                                        vm.config = .fourSevenEight
                                        haptics.tap()
                                    }
                                    PresetChip(title: "Custom", selected: selectedPreset == .custom) {
                                        selectedPreset = .custom
                                        haptics.tap()
                                    }
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Custom config
                        if selectedPreset == .custom {
                            Section {
                                VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                    SectionHeaderView(icon: "slider.horizontal.3", title: "Custom Pattern")

                                    LabeledSlider(title: "Inhale", value: $vm.config.inhale, range: 2...12, step: 1)
                                    LabeledSlider(title: "Hold 1", value: $vm.config.hold1, range: 0...12, step: 1)
                                    LabeledSlider(title: "Exhale", value: $vm.config.exhale, range: 2...16, step: 1)
                                    LabeledSlider(title: "Hold 2", value: $vm.config.hold2, range: 0...12, step: 1)

                                    HStack {
                                        Text("Cycles: \(vm.config.cycles)")
                                            .foregroundStyle(th.colors.textPrimary)
                                        Spacer()
                                        Stepper("", value: Binding(
                                            get: { vm.config.cycles },
                                            set: { vm.config.cycles = max(1, min(30, $0)); haptics.tap() }
                                        ), in: 1...30)
                                        .labelsHidden()
                                    }
                                }
                                .padding(.vertical, th.metrics.spacingM)
                                .listRowBackground(th.colors.card)
                            }
                        }

                        // MARK: - Controls
                        Section {
                            VStack(spacing: th.metrics.spacingM) {
                                switch vm.status {
                                case .idle, .finished:
                                    PrimaryButton(title: "Start") {
                                        if selectedPreset == .box { vm.start(.box) }
                                        else if selectedPreset == .fourSevenEight { vm.start(.fourSevenEight) }
                                        else { vm.start(vm.config) }
                                    }
                                case .running:
                                    PrimaryButton(title: "Pause") { vm.pause() }
                                    PrimaryButton(title: "Reset", style: .secondary) { vm.reset() }
                                case .paused:
                                    PrimaryButton(title: "Resume") { vm.resume() }
                                    PrimaryButton(title: "Reset", style: .secondary) { vm.reset() }
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .environment(\.defaultMinListRowHeight, 10)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Breath")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(th.colors.background, for: .navigationBar)
        }
    }
}

// MARK: - Components

private struct PresetChip: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        let th = themeManager
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(selected ? th.colors.accent.opacity(0.2) : th.colors.card)
                .foregroundStyle(selected ? th.colors.accent : th.colors.textPrimary)
                .overlay(
                    Capsule().stroke(selected ? th.colors.accent : th.colors.separator, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(title) preset"))
    }
}

private struct LabeledSlider: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        let th = themeManager
        HStack {
            Text("\(title): \(Int(value))s")
                .foregroundStyle(th.colors.textPrimary)
            Spacer()
            Slider(value: $value, in: range, step: step)
                .tint(th.colors.accent)
        }
    }
}
