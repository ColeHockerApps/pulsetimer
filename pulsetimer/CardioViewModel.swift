//
//  CardioViewModel.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation


public final class CardioViewModel: ObservableObject {

    // MARK: - Input form

    @Published public var date: Date = Date()
    @Published public var distance: String = ""          // user-facing; km or miles depending on units
    @Published public var durationH: String = "0"
    @Published public var durationM: String = "30"
    @Published public var durationS: String = "0"
    @Published public var avgHR: String = ""

    // MARK: - Unit settings

    /// true = metric (km), false = imperial (miles). Can be bound from SettingsViewModel.
    @Published public var useMetric: Bool = true {
        didSet { recomputeDerived() }
    }

    // MARK: - Derived readouts

    @Published public private(set) var paceLabel: String = "--:-- /km"
    @Published public private(set) var speedLabel: String = "-- km/h"
    @Published public private(set) var canSave: Bool = false

    // MARK: - Listings

    public enum Period: CaseIterable, Identifiable {
        case today, week, month, all
        public var id: String {
            switch self {
            case .today: return "today"
            case .week: return "week"
            case .month: return "month"
            case .all: return "all"
            }
        }
        public var title: String {
            switch self {
            case .today: return "Today"
            case .week: return "This Week"
            case .month: return "This Month"
            case .all: return "All"
            }
        }
    }

    @Published public var period: Period = .week {
        didSet { reload() }
    }

    @Published public private(set) var items: [CardioLog] = []

    // MARK: - Internals

    private let store: LocalStore
    private var bag = Set<AnyCancellable>()

    public init(store: LocalStore = .shared) {
        self.store = store
        bind()
        reload()
        recomputeDerived()
    }

    // MARK: - Public API

    public func addLog() {
        guard let distKm = parsedDistanceKm(), let dur = parsedDurationSec(), dur > 0, distKm > 0 else {
            return
        }
        let hr = Int(avgHR.trimmingCharacters(in: .whitespacesAndNewlines))
        let log = CardioLog(
            date: date,
            distanceKm: distKm,
            durationSec: dur,
            avgHR: hr
        )
        store.upsert(log)
        resetForm()
        reload()
    }

    public func deleteLog(id: UUID) {
        store.removeCardioLog(id: id)
        reload()
    }

    public func updateUnits(useMetric: Bool) {
        // Convert current distance field to the new units while keeping numeric meaning.
        if let current = Double(distance.replacingOccurrences(of: ",", with: ".")) {
            if self.useMetric && !useMetric {
                // km -> miles
                let miles = PaceCalculator.kmToMiles(current)
                distance = Self.formatNumber(miles)
            } else if !self.useMetric && useMetric {
                // miles -> km
                let km = PaceCalculator.milesToKm(current)
                distance = Self.formatNumber(km)
            }
        }
        self.useMetric = useMetric
        recomputeDerived()
    }

    public func reload() {
        let all = store.allCardioLogs()
        let filtered: [CardioLog]
        switch period {
        case .today:
            let key = DateUtils.startOfDay(Date())
            filtered = all.filter { DateUtils.startOfDay($0.date) == key }
        case .week:
            let interval = DateUtils.weekInterval(for: Date())
            filtered = all.filter { $0.date >= interval.start && $0.date <= interval.end }
        case .month:
            let interval = DateUtils.monthInterval(for: Date())
            filtered = all.filter { $0.date >= interval.start && $0.date <= interval.end }
        case .all:
            filtered = all
        }
        items = filtered
    }

    public func resetForm() {
        date = Date()
        distance = ""
        durationH = "0"
        durationM = "30"
        durationS = "0"
        avgHR = ""
        recomputeDerived()
    }

    // MARK: - Bindings

    private func bind() {
        Publishers.CombineLatest4($distance, $durationH, $durationM, $durationS)
            .combineLatest($useMetric)
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.recomputeDerived()
            }
            .store(in: &bag)

        store.$cardioLogs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &bag)
    }

    // MARK: - Compute

    private func recomputeDerived() {
        guard let distKm = parsedDistanceKm(), let dur = parsedDurationSec(), distKm > 0, dur > 0 else {
            paceLabel = useMetric ? "--:-- /km" : "--:-- /mi"
            speedLabel = useMetric ? "-- km/h" : "-- mph"
            canSave = false
            return
        }

        let paceSecPerKm = PaceCalculator.paceSecPerKm(distanceKm: distKm, durationSec: dur)
        let speedKmh = PaceCalculator.speedKmPerHour(distanceKm: distKm, durationSec: dur)

        if useMetric {
            paceLabel = PaceCalculator.formatPace(secPerKm: paceSecPerKm)
            speedLabel = PaceCalculator.formatSpeed(kmPerHour: speedKmh)
        } else {
            // Convert km-based figures to mile-based display
            let miles = PaceCalculator.kmToMiles(1.0)
            let secPerMile = paceSecPerKm * miles
            let mph = speedKmh / miles
            paceLabel = Self.formatPaceImperial(secondsPerMile: secPerMile)
            speedLabel = String(format: "%.1f mph", mph)
        }

        canSave = true
    }

    private func parsedDistanceKm() -> Double? {
        let raw = distance.replacingOccurrences(of: ",", with: ".")
        guard let val = Double(raw), val > 0 else { return nil }
        if useMetric {
            return val
        } else {
            return PaceCalculator.milesToKm(val)
        }
    }

    private func parsedDurationSec() -> TimeInterval? {
        let h = Int(durationH) ?? 0
        let m = Int(durationM) ?? 0
        let s = Int(durationS) ?? 0
        let total = h * 3600 + m * 60 + s
        return total > 0 ? TimeInterval(total) : nil
    }

    // MARK: - Formatting helpers

    private static func formatNumber(_ v: Double) -> String {
        if v >= 10 { return String(format: "%.0f", v.rounded()) }
        return String(format: "%.2f", v)
    }

    private static func formatPaceImperial(secondsPerMile: Double) -> String {
        guard secondsPerMile > 0 else { return "--:-- /mi" }
        let m = Int(secondsPerMile / 60)
        let s = Int(secondsPerMile.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d /mi", m, s)
    }
}
