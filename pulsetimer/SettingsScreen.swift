//
//  SettingsScreen.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation
import WebKit

public struct SettingsScreen: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @StateObject private var vm = SettingsViewModel()

    @State private var showPrivacy: Bool = false
    private let privacyURL: URL = URL(string: "https://telegra.ph/Privacy-Policy-of-Bovedy-Pulse-10-22")!

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

                        // MARK: - Units & Time
                        Section {
                            VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                SectionHeaderView(icon: "ruler", title: "Units & Time")

                                HStack {
                                    Text("Units")
                                        .foregroundStyle(th.colors.textPrimary)
                                    Spacer()
                                    Picker("", selection: Binding(
                                        get: { vm.useMetricUnits },
                                        set: { newVal in vm.setUnits(metric: newVal); haptics.tap() }
                                    )) {
                                        Text("Metric").tag(true)
                                        Text("Imperial").tag(false)
                                    }
                                    .pickerStyle(.segmented)
                                }

                                Toggle(isOn: Binding(
                                    get: { vm.use24hTime },
                                    set: { vm.use24hTime = $0; haptics.tap() }
                                )) {
                                    Text("Use 24-hour time")
                                        .foregroundStyle(th.colors.textPrimary)
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Haptics
                        Section {
                            VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                SectionHeaderView(icon: "waveform", title: "Haptics")
                                Toggle(isOn: Binding(
                                    get: { vm.hapticsEnabled },
                                    set: { vm.hapticsEnabled = $0; haptics.tap() }
                                )) {
                                    Text("Enable haptics")
                                        .foregroundStyle(th.colors.textPrimary)
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - Interval
                        Section {
                            VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                SectionHeaderView(icon: themeManager.icons.interval, title: "Interval")
                                Toggle(isOn: Binding(
                                    get: { vm.autosaveIntervalPreset },
                                    set: { vm.autosaveIntervalPreset = $0; haptics.tap() }
                                )) {
                                    Text("Remember last used config")
                                        .foregroundStyle(th.colors.textPrimary)
                                }
                            }
                            .padding(.vertical, th.metrics.spacingM)
                            .listRowBackground(th.colors.card)
                        }

                        // MARK: - About
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Pulse Timer")
                                        .font(.headline)
                                        .foregroundStyle(th.colors.textPrimary)
                                    Text("Version \(appVersion()) (\(buildNumber()))")
                                        .font(.caption)
                                        .foregroundStyle(th.colors.textSecondary)
                                }

                                PrimaryButton(title: "Privacy") {
                                    showPrivacy = true
                                    haptics.tap()
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(th.colors.background, for: .navigationBar)
            .sheet(isPresented: $showPrivacy) {
                PrivacyView(url: privacyURL)
                    .ignoresSafeArea()
            }
        }
    }

    private func appVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func buildNumber() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - PrivacyView

private struct PrivacyView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.allowsBackForwardNavigationGestures = true
        wv.backgroundColor = .clear
        wv.scrollView.backgroundColor = .clear
        return wv
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
        }
    }
}
