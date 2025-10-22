//
//  SettingsViewModel.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public final class SettingsViewModel: ObservableObject {

    public enum AccentPreset: String, CaseIterable, Identifiable {
        case blue, teal, green, yellow, orange, red, pink, purple, indigo, mint
        public var id: String { rawValue }
        public var label: String {
            switch self {
            case .blue: return "Blue"
            case .teal: return "Teal"
            case .green: return "Green"
            case .yellow: return "Yellow"
            case .orange: return "Orange"
            case .red: return "Red"
            case .pink: return "Pink"
            case .purple: return "Purple"
            case .indigo: return "Indigo"
            case .mint: return "Mint"
            }
        }
        public var color: Color {
            switch self {
            case .blue: return .blue
            case .teal: return .teal
            case .green: return .green
            case .yellow: return .yellow
            case .orange: return .orange
            case .red: return .red
            case .pink: return .pink
            case .purple: return .purple
            case .indigo: return .indigo
            case .mint: return .mint
            }
        }
    }

    @Published public var useMetricUnits: Bool = true
    @Published public var use24hTime: Bool = true
    @Published public var hapticsEnabled: Bool = true
    @Published public var autosaveIntervalPreset: Bool = true
    @Published public private(set) var accent: AccentPreset = .blue

    private let theme: ThemeManager

    public init(theme: ThemeManager = .shared) {
        self.theme = theme
        // Sync initial accent with current theme if needed
        // Keeping .blue as a sane default
    }

    public func setAccent(_ preset: AccentPreset) {
        accent = preset
        theme.setAccent(preset.color)
    }

    public func setUnits(metric: Bool) {
        useMetricUnits = metric
    }
}
