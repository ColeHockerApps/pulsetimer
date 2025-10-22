//
//  IntervalScreen.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public struct IntervalScreen: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @StateObject private var vm = IntervalViewModel()

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

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: th.metrics.spacingL) {

                            VStack(spacing: 4) {
                                Text(vm.phaseLabel)
                                    .font(.headline)
                                    .foregroundColor(th.colors.accent)
                                Text(vm.remainingFormatted)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(th.colors.textPrimary)
                                Text("Cycle \(vm.currentCycle) / \(vm.cycles)")
                                    .font(.subheadline)
                                    .foregroundColor(th.colors.textSecondary)
                            }
                            .padding(.top, 16)

                            ZStack {
                                Circle()
                                    .stroke(th.colors.separator.opacity(0.3), lineWidth: th.metrics.ringThickness)
                                Circle()
                                    .trim(from: 0, to: vm.totalProgress)
                                    .stroke(th.colors.accent, style: StrokeStyle(lineWidth: th.metrics.ringThickness, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.2), value: vm.totalProgress)
                                Text("\(Int(vm.totalProgress * 100))%")
                                    .font(.headline)
                                    .foregroundColor(th.colors.textPrimary)
                            }
                            .frame(width: 160, height: 160)
                            .padding(.vertical, 8)

                            let configLocked = vm.status != .idle

                            VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                SectionHeaderView(icon: th.icons.interval, title: "Configuration")

                                HStack {
                                    Text("Work: \(Int(vm.workSec))s")
                                        .foregroundColor(th.colors.textPrimary)
                                    Spacer()
                                    Slider(value: $vm.workSec, in: 5...180, step: 5)
                                        .tint(th.colors.accent)
                                        .disabled(configLocked)
                                        .onChange(of: vm.workSec) { _ in haptics.tap() }
                                }

                                HStack {
                                    Text("Rest: \(Int(vm.restSec))s")
                                        .foregroundColor(th.colors.textPrimary)
                                    Spacer()
                                    Slider(value: $vm.restSec, in: 0...120, step: 5)
                                        .tint(th.colors.accent)
                                        .disabled(configLocked)
                                        .onChange(of: vm.restSec) { _ in haptics.tap() }
                                }

                                HStack {
                                    Text("Cycles: \(vm.cycles)")
                                        .foregroundColor(th.colors.textPrimary)
                                    Spacer()
                                    Stepper("", value: $vm.cycles, in: 1...20)
                                        .labelsHidden()
                                        .disabled(configLocked)
                                        .onChange(of: vm.cycles) { _ in haptics.tap() }
                                }

                                if configLocked {
                                    Text("Locked while timer is active. Reset to edit.")
                                        .font(.caption)
                                        .foregroundColor(th.colors.textSecondary)
                                }
                            }
                            .padding()
                            .background(th.colors.card)
                            .cornerRadius(th.metrics.cornerL)
                            .opacity(configLocked ? 0.75 : 1)

                            VStack(spacing: th.metrics.spacingM) {
                                if vm.status == .running {
                                    PrimaryButton(title: "Pause") { vm.pause() }
                                    PrimaryButton(title: "Reset", style: .secondary) { vm.reset() }
                                } else if vm.status == .paused {
                                    PrimaryButton(title: "Resume") { vm.resume() }
                                    PrimaryButton(title: "Reset", style: .secondary) { vm.reset() }
                                } else if vm.status == .finished {
                                    PrimaryButton(title: "Reset", style: .secondary) { vm.reset() }
                                } else {
                                    PrimaryButton(title: "Start", enabled: vm.canStart) { vm.start() }
                                }
                            }
                            .padding(.bottom, 40)
                        }
                        .padding(.horizontal, th.metrics.spacingL)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Interval Timer")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
