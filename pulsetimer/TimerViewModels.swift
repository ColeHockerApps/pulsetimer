//
//  TimerViewModels.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

// MARK: - IntervalViewModel


public final class IntervalViewModel: ObservableObject {

    @Published public var selectedPreset: IntervalPreset? {
        didSet { applyPreset() }
    }

    @Published public var workSec: Double = 30
    @Published public var restSec: Double = 15
    @Published public var cycles: Int = 8

    @Published public private(set) var status: TimerEngine.Status = .idle
    @Published public private(set) var phase: TimerEngine.Phase = .work
    @Published public private(set) var currentCycle: Int = 0
    @Published public private(set) var remainingSec: Double = 0
    @Published public private(set) var elapsedSec: Double = 0
    @Published public private(set) var phaseProgress: Double = 0
    @Published public private(set) var totalProgress: Double = 0

    private let engine: TimerEngine
    private let haptics: HapticsManager
    private var bag = Set<AnyCancellable>()

    public init(engine: TimerEngine = TimerEngine(), haptics: HapticsManager = HapticsManager()) {
        self.engine = engine
        self.haptics = haptics
        bindEngine()
    }

    private func bindEngine() {
        engine.$status.sink { [weak self] in
            self?.status = $0
            if $0 == .finished { self?.haptics.confirm() }
        }.store(in: &bag)

        engine.$phase.sink { [weak self] in
            self?.phase = $0
            self?.haptics.tap()
        }.store(in: &bag)

        engine.$currentCycle.assign(to: &$currentCycle)
        engine.$remainingSec.map { $0 }.assign(to: &$remainingSec)
        engine.$elapsedSec.map { $0 }.assign(to: &$elapsedSec)
        engine.$phaseProgress.assign(to: &$phaseProgress)
        engine.$totalProgress.assign(to: &$totalProgress)
    }

    private func applyPreset() {
        guard let p = selectedPreset else { return }
        workSec = p.workSec
        restSec = p.restSec
        cycles = p.cycles
    }

    public func start() {
        let cfg = TimerEngine.Config(workSec: workSec, restSec: restSec, cycles: cycles)
        engine.start(cfg)
        haptics.play(.medium)
    }

    public func pause() {
        engine.pause()
        haptics.play(.light)
    }

    public func resume() {
        engine.resume()
        haptics.play(.light)
    }

    public func reset() {
        engine.reset()
        haptics.play(.warning)
    }

    public var phaseLabel: String {
        switch phase {
        case .work: return "WORK"
        case .rest: return "REST"
        }
    }

    public var remainingFormatted: String {
        DateUtils.formatDuration(remainingSec)
    }

    public var totalPlannedFormatted: String {
        let cfg = TimerEngine.Config(workSec: workSec, restSec: restSec, cycles: cycles)
        return DateUtils.formatDuration(cfg.totalPlannedSec)
    }

    public var canStart: Bool {
        workSec >= 1 && cycles >= 1
    }
}

// MARK: - RepsViewModel

@MainActor
public final class RepsViewModel: ObservableObject {

    @Published public var targetSets: Int = 4
    @Published public var targetReps: Int = 12

    @Published public private(set) var currentSet: Int = 1
    @Published public private(set) var currentReps: Int = 0
    @Published public private(set) var completedSets: Int = 0
    @Published public private(set) var totalReps: Int = 0
    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var isFinished: Bool = false

    private let haptics: HapticsManager

    public init(haptics: HapticsManager = HapticsManager()) {
        self.haptics = haptics
    }

    public func startSession() {
        resetSession()
        isActive = true
        haptics.play(.medium)
    }

    public func incrementRep() {
        guard isActive, !isFinished else { return }
        currentReps += 1
        totalReps += 1
        haptics.tap()
        if currentReps >= targetReps {
            completeSet()
        }
    }

    public func decrementRep() {
        guard isActive, !isFinished else { return }
        guard currentReps > 0 else { return }
        currentReps -= 1
        totalReps = max(0, totalReps - 1)
        haptics.tap()
    }

    public func completeSet() {
        guard isActive, !isFinished else { return }
        completedSets += 1
        haptics.confirm()
        if currentSet >= targetSets {
            isFinished = true
            isActive = false
        } else {
            currentSet += 1
            currentReps = 0
        }
    }

    public func undoSet() {
        guard completedSets > 0 else { return }
        completedSets -= 1
        currentSet = max(1, currentSet - 1)
        currentReps = 0
        isFinished = false
        isActive = true
        haptics.play(.warning)
    }

    public func resetSession() {
        currentSet = 1
        currentReps = 0
        completedSets = 0
        totalReps = 0
        isFinished = false
        isActive = false
    }

    public var setsProgress: Double {
        guard targetSets > 0 else { return 0 }
        return min(Double(completedSets) / Double(targetSets), 1.0)
    }

    public var repsProgress: Double {
        guard targetReps > 0 else { return 0 }
        return min(Double(currentReps) / Double(targetReps), 1.0)
    }

    public var title: String {
        isFinished ? "Session complete" : "Set \(currentSet) of \(targetSets)"
    }
}

// MARK: - BreathViewModel

@MainActor
public final class BreathViewModel: ObservableObject {

    public enum Phase: String, CaseIterable, Identifiable {
        case inhale
        case hold1
        case exhale
        case hold2
        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .inhale: return "INHALE"
            case .hold1:  return "HOLD"
            case .exhale: return "EXHALE"
            case .hold2:  return "HOLD"
            }
        }
    }

    public struct Config: Equatable {
        public var inhale: Double
        public var hold1: Double
        public var exhale: Double
        public var hold2: Double
        public var cycles: Int

        public init(inhale: Double, hold1: Double, exhale: Double, hold2: Double, cycles: Int) {
            self.inhale = max(1, inhale)
            self.hold1 = max(0, hold1)
            self.exhale = max(1, exhale)
            self.hold2 = max(0, hold2)
            self.cycles = max(1, cycles)
        }

        public static let box = Config(inhale: 4, hold1: 4, exhale: 4, hold2: 4, cycles: 6)
        public static let fourSevenEight = Config(inhale: 4, hold1: 7, exhale: 8, hold2: 0, cycles: 6)

        public var cycleDuration: Double { inhale + hold1 + exhale + hold2 }
        public var totalPlanned: Double { cycleDuration * Double(cycles) }
    }

    @Published public private(set) var status: TimerEngine.Status = .idle
    @Published public private(set) var phase: Phase = .inhale
    @Published public private(set) var cycleIndex: Int = 0 // 1-based
    @Published public private(set) var remainingInPhase: Double = 0
    @Published public private(set) var phaseProgress: Double = 0
    @Published public private(set) var totalProgress: Double = 0

    @Published public var config: Config = .box

    private var timer: DispatchSourceTimer?
    private var phaseEndDate: Date?
    private var phaseDuration: Double = 0
    private var elapsedTotal: Double = 0

    private let haptics: HapticsManager

    public init(haptics: HapticsManager = HapticsManager()) {
        self.haptics = haptics
    }

    public func start(_ cfg: Config? = nil) {
        reset()
        if let cfg { config = cfg }
        status = .running
        cycleIndex = 1
        phase = .inhale
        startPhase(duration: config.inhale)
        haptics.play(.medium)
    }

    public func pause() {
        guard status == .running else { return }
        status = .paused
        captureRemaining()
        stopTimer()
        haptics.play(.light)
    }

    public func resume() {
        guard status == .paused else { return }
        status = .running
        startPhase(duration: remainingInPhase)
        haptics.play(.light)
    }

    public func reset() {
        stopTimer()
        status = .idle
        phase = .inhale
        cycleIndex = 0
        remainingInPhase = 0
        phaseProgress = 0
        totalProgress = 0
        elapsedTotal = 0
    }

    private func startPhase(duration: Double) {
        phaseDuration = max(0.01, duration)
        phaseEndDate = Date().addingTimeInterval(phaseDuration)
        startTimer()
        tick() // immediate
    }

    private func nextPhase() {
        switch phase {
        case .inhale:
            if config.hold1 > 0 {
                phase = .hold1
                startPhase(duration: config.hold1)
            } else {
                phase = .exhale
                startPhase(duration: config.exhale)
            }
        case .hold1:
            phase = .exhale
            startPhase(duration: config.exhale)
        case .exhale:
            if config.hold2 > 0 {
                phase = .hold2
                startPhase(duration: config.hold2)
            } else {
                endCycleOrFinish()
            }
        case .hold2:
            endCycleOrFinish()
        }
        haptics.tap()
    }

    private func endCycleOrFinish() {
        if cycleIndex < config.cycles {
            cycleIndex += 1
            phase = .inhale
            startPhase(duration: config.inhale)
        } else {
            finishAll()
        }
    }

    private func finishAll() {
        stopTimer()
        status = .finished
        remainingInPhase = 0
        phaseProgress = 1
        totalProgress = 1
        haptics.confirm()
    }

    private func captureRemaining() {
        guard let end = phaseEndDate else { return }
        remainingInPhase = max(0, end.timeIntervalSince(Date()))
    }

    // Timer

    private func startTimer() {
        stopTimer()
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        t.schedule(deadline: .now(), repeating: .milliseconds(100), leeway: .milliseconds(10))
        t.setEventHandler { [weak self] in
            self?.tick()
        }
        t.resume()
        timer = t
    }

    private func stopTimer() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        guard status == .running, let end = phaseEndDate else { return }
        let now = Date()
        let remaining = max(0, end.timeIntervalSince(now))
        remainingInPhase = remaining

        let elapsedInPhase = max(0, phaseDuration - remaining)
        phaseProgress = min(1, max(0, elapsedInPhase / max(0.0001, phaseDuration)))

        elapsedTotal += 0.1 // approximate; visually sufficient for progress bar
        let planned = max(0.0001, config.totalPlanned)
        totalProgress = min(1, max(0, elapsedTotal / planned))

        if remaining <= 0.0001 {
            nextPhase()
        }
    }

    public var phaseLabel: String { phase.label }
    public var remainingLabel: String { String(format: "%.0fs", remainingInPhase.rounded(.toNearestOrAwayFromZero)) }
    public var totalPlannedLabel: String { DateUtils.formatDuration(config.totalPlanned) }
}
