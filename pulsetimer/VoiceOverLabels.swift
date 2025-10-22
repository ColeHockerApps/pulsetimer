//
//  VoiceOverLabels.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public enum VoiceOverLabels {

    // MARK: - Sports

    public static func forSportTag(_ tag: SportTag) -> String {
        switch tag {
        case .americanFootball: return "American football"
        case .soccer: return "Soccer"
        case .basketball: return "Basketball"
        case .tennis: return "Tennis"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .boxing: return "Boxing"
        case .crossfit: return "CrossFit"
        case .yoga: return "Yoga"
        }
    }

    // MARK: - Goals

    public static func forGoalType(_ type: DailyGoal.GoalType) -> String {
        switch type {
        case .duration: return "Goal duration"
        case .distance: return "Goal distance"
        case .exercises: return "Goal exercises"
        case .calories: return "Goal calories"
        case .intervals: return "Goal intervals"
        }
    }

    // MARK: - Interval timer

    public static func forIntervalPhase(_ phase: TimerEngine.Phase) -> String {
        switch phase {
        case .work: return "Work interval"
        case .rest: return "Rest interval"
        }
    }

    public static func forIntervalStatus(_ status: TimerEngine.Status) -> String {
        switch status {
        case .idle: return "Idle"
        case .running: return "Running"
        case .paused: return "Paused"
        case .finished: return "Finished"
        }
    }

    public static func forTimerProgress(_ percent: Double) -> String {
        let val = Int(max(0, min(1, percent)) * 100)
        return "Timer progress \(val) percent"
    }

    // MARK: - Breath

    public static func forBreathPhase(_ phase: BreathViewModel.Phase) -> String {
        switch phase {
        case .inhale: return "Inhale"
        case .hold1: return "Hold breath"
        case .exhale: return "Exhale"
        case .hold2: return "Hold after exhale"
        }
    }

    // MARK: - UI

    public static func forButtonAction(_ style: PrimaryButton.Style, enabled: Bool) -> String {
        guard enabled else { return "Disabled button" }
        switch style {
        case .primary: return "Primary action"
        case .secondary: return "Secondary action"
        case .destructive: return "Destructive action"
        }
    }

    // MARK: - Entities

    public static func forSet(_ set: ExerciseSet) -> String {
        if set.weight > 0 {
            return "Set with \(set.reps) repetitions, \(Int(set.weight)) kilograms, rest \(Int(set.restSec)) seconds"
        } else {
            return "Set with \(set.reps) repetitions, rest \(Int(set.restSec)) seconds"
        }
    }

    public static func forExercise(_ exercise: Exercise) -> String {
        let tags = exercise.sportTags.map { $0.rawValue }.joined(separator: ", ")
        return "Exercise \(exercise.name), \(exercise.sets.count) sets, tags: \(tags)"
    }

    public static func forCardioLog(_ log: CardioLog) -> String {
        let date = DateUtils.shortDate(log.date)
        let distance = String(format: "%.2f kilometers", log.distanceKm)
        let duration = DateUtils.formatDuration(log.durationSec)
        return "Cardio on \(date), \(distance), \(duration)"
    }

    public static func forTemplate(_ template: ExerciseTemplate) -> String {
        return "Template \(template.name), \(template.defaultSets.count) sets"
    }

    public static func forIntervalPreset(_ preset: IntervalPreset) -> String {
        return "Preset \(preset.name), work \(Int(preset.workSec)) seconds, rest \(Int(preset.restSec)) seconds, \(preset.cycles) cycles"
    }
}
