//
//  SharedUI.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

// MARK: - PrimaryButton

public struct PrimaryButton: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    public enum Style {
        case primary
        case secondary
        case destructive
    }

    private let title: String
    private let enabled: Bool
    private let style: Style
    private let action: () -> Void

    public init(title: String, enabled: Bool = true, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.enabled = enabled
        self.style = style
        self.action = action
    }

    public var body: some View {
        let th = themeManager

        Button {
            guard enabled else { return }
            action()
            switch style {
            case .primary: haptics.play(.medium)
            case .secondary: haptics.tap()
            case .destructive: haptics.reject()
            }
        } label: {
            Text(title)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(foreground)
                .background(background)
                .overlay(RoundedRectangle(cornerRadius: th.metrics.cornerL).stroke(border, lineWidth: 1))
                .cornerRadius(th.metrics.cornerL)
                .opacity(enabled ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .disabled(!enabled)
    }

    private var foreground: Color {
        let th = themeManager
        switch style {
        case .primary: return Color.black
        case .secondary: return th.colors.textPrimary
        case .destructive: return Color.white
        }
    }

    private var background: some View {
        let th = themeManager
        return Group {
            switch style {
            case .primary:
                RoundedRectangle(cornerRadius: th.metrics.cornerL, style: .continuous).fill(th.colors.accent)
            case .secondary:
                RoundedRectangle(cornerRadius: th.metrics.cornerL, style: .continuous).fill(th.colors.card)
            case .destructive:
                RoundedRectangle(cornerRadius: th.metrics.cornerL, style: .continuous).fill(th.colors.error)
            }
        }
    }

    private var border: Color {
        let th = themeManager
        switch style {
        case .primary: return th.colors.accent.opacity(0.001) // invisible, keeps layout consistent
        case .secondary: return th.colors.separator
        case .destructive: return th.colors.error.opacity(0.75)
        }
    }
}

// MARK: - SectionHeaderView

public struct SectionHeaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    private let icon: String
    private let title: String
    private let subtitle: String?

    public init(icon: String, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        let th = themeManager
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(th.colors.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(th.colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(th.colors.textSecondary)
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(subtitle == nil ? title : "\(title), \(subtitle!)"))
    }
}

// MARK: - StatChipView

public struct StatChipView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    private let title: String
    private let value: String
    private let system: String?

    public init(title: String, value: String, system: String? = nil) {
        self.title = title
        self.value = value
        self.system = system
    }

    public var body: some View {
        let th = themeManager
        HStack(spacing: 8) {
            if let system {
                Image(systemName: system)
                    .foregroundStyle(th.colors.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(th.colors.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(th.colors.textPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(th.colors.card)
        .overlay(RoundedRectangle(cornerRadius: themeManager.metrics.cornerS).stroke(th.colors.separator, lineWidth: 1))
        .cornerRadius(themeManager.metrics.cornerS)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title) \(value)"))
    }
}

// MARK: - ConfirmButton (confirmation dialog helper)

public struct ConfirmButton<Label: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    private let title: String?
    private let message: String?
    private let confirmTitle: String
    private let confirmRole: ButtonRole?
    private let onConfirm: () -> Void
    private let label: () -> Label

    @State private var showDialog: Bool = false

    public init(
        title: String? = "Confirm",
        message: String? = nil,
        confirmTitle: String = "Confirm",
        confirmRole: ButtonRole? = .destructive,
        onConfirm: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.confirmRole = confirmRole
        self.onConfirm = onConfirm
        self.label = label
    }

    public var body: some View {
        Button {
            showDialog = true
        } label: {
            label()
        }
        .confirmationDialog(
            title ?? "Confirm",
            isPresented: $showDialog,
            titleVisibility: .visible
        ) {
            Button(confirmTitle, role: confirmRole) {
                onConfirm()
                if confirmRole == .destructive { haptics.reject() } else { haptics.confirm() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let message {
                Text(message)
            }
        }
    }
}
