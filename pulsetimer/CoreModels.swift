//
//  CoreModels.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

// MARK: - SportTag

public enum SportTag: String, CaseIterable, Codable, Identifiable {
    case americanFootball = "American Football"
    case soccer = "Soccer"
    case basketball = "Basketball"
    case tennis = "Tennis"
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case boxing = "Boxing"
    case crossfit = "Crossfit"
    case yoga = "Yoga"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .americanFootball: return "football.fill"
        case .soccer: return "soccerball"
        case .basketball: return "basketball.fill"
        case .tennis: return "tennis.racket"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .boxing: return "figure.boxing"
        case .crossfit: return "bolt.circle"
        case .yoga: return "figure.mind.and.body"
        }
    }

    public var color: Color {
        switch self {
        case .americanFootball: return .brown
        case .soccer: return .green
        case .basketball: return .orange
        case .tennis: return .yellow
        case .running: return .cyan
        case .cycling: return .purple
        case .swimming: return .blue
        case .boxing: return .red
        case .crossfit: return .gray
        case .yoga: return .mint
        }
    }
}

// MARK: - Exercise

public struct Exercise: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var notes: String
    public var sportTags: [SportTag]
    public var sets: [ExerciseSet]
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        sportTags: [SportTag] = [],
        sets: [ExerciseSet] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.sportTags = sportTags
        self.sets = sets
        self.createdAt = Date()
    }
}

// MARK: - ExerciseSet

public struct ExerciseSet: Identifiable, Codable, Equatable {
    public let id: UUID
    public var reps: Int
    public var weight: Double
    public var restSec: TimeInterval

    public init(id: UUID = UUID(), reps: Int, weight: Double = 0, restSec: TimeInterval = 60) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.restSec = restSec
    }

    public static let empty = ExerciseSet(reps: 0, weight: 0, restSec: 60)
}
