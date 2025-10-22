//
//  CardioScreen.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public struct CardioScreen: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @StateObject private var vm = CardioViewModel()

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

                        // MARK: - Units
                        Section {
                            HStack {
                                Text("Units")
                                    .foregroundStyle(th.colors.textPrimary)
                                Spacer()
                                Picker("", selection: Binding<Bool>(
                                    get: { vm.useMetric },
                                    set: { newVal in
                                        vm.updateUnits(useMetric: newVal)
                                        haptics.tap()
                                    }
                                )) {
                                    Text("Metric").tag(true)
                                    Text("Imperial").tag(false)
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - New log form
                        Section {
                            VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                SectionHeaderView(icon: themeManager.icons.cardio, title: "New Cardio Log")

                                DatePicker("Date", selection: $vm.date, displayedComponents: [.date, .hourAndMinute])
                                    .tint(th.colors.accent)
                                    .foregroundStyle(th.colors.textPrimary)

                                HStack(spacing: th.metrics.spacingM) {
                                    VStack(alignment: .leading) {
                                        Text(vm.useMetric ? "Distance (km)" : "Distance (mi)")
                                            .font(.caption)
                                            .foregroundStyle(th.colors.textSecondary)
                                        TextField("0", text: $vm.distance)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Avg HR")
                                            .font(.caption)
                                            .foregroundStyle(th.colors.textSecondary)
                                        TextField("bpm", text: $vm.avgHR)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }

                                HStack(spacing: th.metrics.spacingM) {
                                    DurationField(title: "h", text: $vm.durationH)
                                    DurationField(title: "m", text: $vm.durationM)
                                    DurationField(title: "s", text: $vm.durationS)
                                }

                                HStack(spacing: th.metrics.spacingM) {
                                    StatTile(title: "Pace", value: vm.paceLabel, system: "speedometer")
                                    StatTile(title: "Speed", value: vm.speedLabel, system: "gauge.with.needle")
                                }

                                PrimaryButton(title: "Add Log", enabled: vm.canSave) {
                                    vm.addLog()
                                    haptics.confirm()
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Period filter
                        Section {
                            Picker("Period", selection: $vm.period) {
                                ForEach(CardioViewModel.Period.allCases) { p in
                                    Text(p.title).tag(p)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .listRowBackground(th.colors.card)

                        // MARK: - Logs list
                        Section {
                            if vm.items.isEmpty {
                                HStack {
                                    Image(systemName: "tray")
                                        .foregroundStyle(th.colors.textSecondary)
                                    Text("No logs")
                                        .foregroundStyle(th.colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                                .listRowBackground(th.colors.card)
                            } else {
                                ForEach(vm.items) { item in
                                    CardioRow(item: item)
                                        .listRowBackground(th.colors.card)
                                        .swipeActions {
                                            Button(role: .destructive) {
                                                vm.deleteLog(id: item.id)
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
            .navigationTitle("Cardio")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(th.colors.background, for: .navigationBar)
        }
    }
}

// MARK: - Components

private struct DurationField: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    @Binding var text: String

    var body: some View {
        let th = themeManager
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(th.colors.textSecondary)
            TextField("0", text: $text)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 90)
        }
    }
}

private struct StatTile: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let value: String
    let system: String

    var body: some View {
        let th = themeManager
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: system)
                    .foregroundStyle(th.colors.accent)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(th.colors.textSecondary)
            }
            Text(value)
                .font(.headline)
                .foregroundStyle(th.colors.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(th.colors.card)
        .overlay(RoundedRectangle(cornerRadius: th.metrics.cornerS).stroke(th.colors.separator, lineWidth: 1))
        .cornerRadius(th.metrics.cornerS)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title) \(value)"))
    }
}

private struct CardioRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let item: CardioLog

    var body: some View {
        let th = themeManager
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(DateUtils.shortDate(item.date))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(th.colors.textPrimary)
                Spacer()
                Text(DateUtils.shortTime(item.date))
                    .font(.caption)
                    .foregroundStyle(th.colors.textSecondary)
            }

            HStack(spacing: 12) {
                Label(String(format: "%.2f km", item.distanceKm), systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    .foregroundStyle(th.colors.textSecondary)
                Label(DateUtils.formatDuration(item.durationSec), systemImage: "clock")
                    .foregroundStyle(th.colors.textSecondary)
                if let hr = item.avgHR {
                    Label("\(hr) bpm", systemImage: "heart.fill")
                        .foregroundStyle(th.colors.textSecondary)
                }
            }
            .font(.caption)

            HStack(spacing: 16) {
                Badge(title: "Pace", value: item.pace)
                Badge(title: "Speed", value: item.speed)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Cardio \(DateUtils.shortDate(item.date)) \(item.pace) \(item.speed)"))
    }
}

private struct Badge: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let value: String

    var body: some View {
        let th = themeManager
        HStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(th.colors.textSecondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(th.colors.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(th.colors.card)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(th.colors.separator, lineWidth: 1))
    }
}
