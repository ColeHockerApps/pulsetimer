//
//  HapticsManager.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation
import UIKit


public final class HapticsManager: ObservableObject {

    public enum Style {
        case light
        case medium
        case heavy
        case success
        case warning
        case error
    }

    private var generatorImpact = UIImpactFeedbackGenerator(style: .medium)
    private var generatorNotification = UINotificationFeedbackGenerator()
    private var generatorSelection = UISelectionFeedbackGenerator()
    private var lastFeedbackTime: Date = .distantPast
    private let minInterval: TimeInterval = 0.1

    public init() {
        prepare()
    }

    public func prepare() {
        generatorImpact.prepare()
        generatorNotification.prepare()
        generatorSelection.prepare()
    }

    public func play(_ style: Style) {
        let now = Date()
        guard now.timeIntervalSince(lastFeedbackTime) > minInterval else { return }
        lastFeedbackTime = now

        switch style {
        case .light:
            generatorImpact = UIImpactFeedbackGenerator(style: .light)
            generatorImpact.impactOccurred()
        case .medium:
            generatorImpact = UIImpactFeedbackGenerator(style: .medium)
            generatorImpact.impactOccurred()
        case .heavy:
            generatorImpact = UIImpactFeedbackGenerator(style: .heavy)
            generatorImpact.impactOccurred()
        case .success:
            generatorNotification.notificationOccurred(.success)
        case .warning:
            generatorNotification.notificationOccurred(.warning)
        case .error:
            generatorNotification.notificationOccurred(.error)
        }
    }

    public func tap() {
        play(.light)
    }

    public func confirm() {
        play(.success)
    }

    public func reject() {
        play(.error)
    }
}
