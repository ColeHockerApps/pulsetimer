//
//  PlanningModels.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

// MARK: - ExerciseTemplate

public struct ExerciseTemplate: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var defaultSets: [ExerciseSet]
    public var notes: String
    public var tags: [SportTag]

    public init(
        id: UUID = UUID(),
        name: String,
        defaultSets: [ExerciseSet] = [],
        notes: String = "",
        tags: [SportTag] = []
    ) {
        self.id = id
        self.name = name
        self.defaultSets = defaultSets
        self.notes = notes
        self.tags = tags
    }

    public func instantiate() -> Exercise {
        Exercise(
            name: name,
            notes: notes,
            sportTags: tags,
            sets: defaultSets
        )
    }
}

// MARK: - IntervalPreset

public struct IntervalPreset: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var workSec: TimeInterval
    public var restSec: TimeInterval
    public var cycles: Int
    public var color: ColorCodable

    public init(
        id: UUID = UUID(),
        name: String,
        workSec: TimeInterval,
        restSec: TimeInterval,
        cycles: Int,
        color: Color = .cyan
    ) {
        self.id = id
        self.name = name
        self.workSec = workSec
        self.restSec = restSec
        self.cycles = cycles
        self.color = ColorCodable(color)
    }
}

// Codable color wrapper
public struct ColorCodable: Codable, Equatable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(_ color: Color) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r); green = Double(g); blue = Double(b); alpha = Double(a)
    }

    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - DailyGoal

public struct DailyGoal: Identifiable, Codable, Equatable {
    public let id: UUID
    public var date: Date
    public var type: GoalType
    public var target: Double
    public var progress: Double

    public init(
        id: UUID = UUID(),
        date: Date = DateUtils.today(),
        type: GoalType,
        target: Double,
        progress: Double = 0
    ) {
        self.id = id
        self.date = DateUtils.startOfDay(date)
        self.type = type
        self.target = target
        self.progress = progress
    }

    public enum GoalType: String, Codable, CaseIterable, Identifiable {
        case duration = "Duration"
        case distance = "Distance"
        case exercises = "Exercises"
        case calories = "Calories"
        case intervals = "Intervals"

        public var id: String { rawValue }
    }

    public var percent: Double {
        guard target > 0 else { return 0 }
        return min(progress / target, 1.0)
    }
}

// MARK: - CardioLog

public struct CardioLog: Identifiable, Codable, Equatable {
    public let id: UUID
    public var date: Date
    public var distanceKm: Double
    public var durationSec: TimeInterval
    public var avgHR: Int?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        distanceKm: Double,
        durationSec: TimeInterval,
        avgHR: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.distanceKm = distanceKm
        self.durationSec = durationSec
        self.avgHR = avgHR
    }

    public var pace: String {
        DateUtils.formatPace(distanceKm: distanceKm, durationSec: durationSec)
    }

    public var speed: String {
        DateUtils.formatSpeed(distanceKm: distanceKm, durationSec: durationSec)
    }
}
