//
//  PreviewData.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public enum PreviewData {

    public static let sampleSet = ExerciseSet(reps: 12, weight: 35, restSec: 60)

    public static let sampleExercise = Exercise(
        name: "Bench Press",
        notes: "Focus on controlled movement and stable breathing.",
        sportTags: [.crossfit, .boxing],
        sets: [
            ExerciseSet(reps: 10, weight: 40, restSec: 60),
            ExerciseSet(reps: 8, weight: 45, restSec: 60),
            ExerciseSet(reps: 6, weight: 50, restSec: 90)
        ]
    )

    public static let sampleTemplate = ExerciseTemplate(
        id: UUID(),
        name: "Push Routine",
        defaultSets: [
            ExerciseSet(reps: 12, weight: 30, restSec: 60),
            ExerciseSet(reps: 10, weight: 35, restSec: 60)
        ],
        notes: "Basic chest routine for beginners.",
        tags: [.crossfit, .yoga]
    )

    public static let samplePreset = IntervalPreset(
        id: UUID(),
        name: "Tabata 20/10",
        workSec: 20,
        restSec: 10,
        cycles: 8,
        color: .orange
    )

    public static let sampleCardio = CardioLog(
        id: UUID(),
        date: Date(),
        distanceKm: 5.25,
        durationSec: 1800,
        avgHR: 145
    )

    public static let sampleGoal = DailyGoal(
        id: UUID(),
        type: .distance,
        target: 5.0,
        progress: 3.4
    )

    public static let sampleStats: [CardioLog] = [
        CardioLog(id: UUID(), date: Date().addingTimeInterval(-86400 * 1), distanceKm: 5.0, durationSec: 1600, avgHR: 140),
        CardioLog(id: UUID(), date: Date().addingTimeInterval(-86400 * 2), distanceKm: 4.6, durationSec: 1550, avgHR: 138),
        CardioLog(id: UUID(), date: Date().addingTimeInterval(-86400 * 3), distanceKm: 6.0, durationSec: 1700, avgHR: 142),
        CardioLog(id: UUID(), date: Date().addingTimeInterval(-86400 * 4), distanceKm: 5.4, durationSec: 1650, avgHR: 141)
    ]

    public static let sampleTags: [SportTag] = [.running, .cycling, .swimming, .basketball, .americanFootball]

    public static let sampleGoals: [DailyGoal] = [
        DailyGoal(id: UUID(), type: .distance, target: 5.0, progress: 2.3),
        DailyGoal(id: UUID(), type: .calories, target: 400, progress: 250),
        DailyGoal(id: UUID(), type: .duration, target: 3600, progress: 1800)
    ]
}
