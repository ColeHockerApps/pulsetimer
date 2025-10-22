//
//  AppState.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation


public final class AppState: ObservableObject {

    @Published public var selectedTab: TabIdentifier = .interval
    @Published public private(set) var isActive: Bool = true

    public let eventBus = PassthroughSubject<AppEvent, Never>()

    public init() {}

    public func handleAppBecameActive() {
        isActive = true
        eventBus.send(.didBecomeActive)
    }

    public func handleAppWillResignActive() {
        isActive = false
        eventBus.send(.willResignActive)
    }

    public func handleAppEnteredBackground() {
        eventBus.send(.didEnterBackground)
    }

    public enum TabIdentifier: String, CaseIterable, Codable {
        case interval
        case reps
        case cardio
        case breath
        case exercises
        case settings
    }

    public enum AppEvent {
        case didBecomeActive
        case willResignActive
        case didEnterBackground
    }
}
