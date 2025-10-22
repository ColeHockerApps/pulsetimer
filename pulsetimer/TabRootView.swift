//
//  TabRootView.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public struct TabRootView: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    private enum Tab: Hashable {
        case interval, reps, cardio, exercises, settings
    }

    @State private var selection: Tab = .interval

    public init() {}

    public var body: some View {
        let th = themeManager

        TabView(selection: $selection) {

            IntervalScreen()
                .tabItem {
                    Image(systemName: th.icons.interval)
                    Text("Interval")
                }
                .tag(Tab.interval)

            RepsScreen()
                .tabItem {
                    Image(systemName: th.icons.reps)
                    Text("Reps")
                }
                .tag(Tab.reps)

            CardioScreen()
                .tabItem {
                    Image(systemName: th.icons.cardio)
                    Text("Cardio")
                }
                .tag(Tab.cardio)

            ExercisesScreen()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Exercises")
                }
                .tag(Tab.exercises)

            SettingsScreen()
                .tabItem {
                    Image(systemName: th.icons.settings)
                    Text("Settings")
                }
                .tag(Tab.settings)
        }
        .tint(th.colors.accent)
        .onChange(of: selection) { _ in haptics.play(.light) }
    }
}
