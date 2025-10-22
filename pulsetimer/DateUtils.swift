//
//  DateUtils.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public enum DateUtils {

    public static func today() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    public static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    public static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    public static func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }

    public static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%02dh %02dm %02ds", h, m, s)
        } else if m > 0 {
            return String(format: "%02dm %02ds", m, s)
        } else {
            return String(format: "%02ds", s)
        }
    }

    public static func formatPace(distanceKm: Double, durationSec: Double) -> String {
        guard durationSec > 0 && distanceKm > 0 else { return "--:-- /km" }
        let pace = durationSec / distanceKm
        let m = Int(pace / 60)
        let s = Int(pace.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d /km", m, s)
    }

    public static func formatSpeed(distanceKm: Double, durationSec: Double) -> String {
        guard durationSec > 0 && distanceKm > 0 else { return "-- km/h" }
        let hours = durationSec / 3600.0
        let speed = distanceKm / hours
        return String(format: "%.1f km/h", speed)
    }

    public static func secondsFrom(hours: Int, minutes: Int, seconds: Int) -> TimeInterval {
        Double(hours * 3600 + minutes * 60 + seconds)
    }

    public static func addDays(_ date: Date, days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    public static func lastDays(_ count: Int) -> [Date] {
        let today = startOfDay(Date())
        return (0..<count).map { i in
            Calendar.current.date(byAdding: .day, value: -i, to: today)!
        }.reversed()
    }

    public static func weekInterval(for date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let end = cal.date(byAdding: .day, value: 6, to: start)!
        return (startOfDay(start), end)
    }

    public static func monthInterval(for date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        let start = cal.date(from: comps)!
        let range = cal.range(of: .day, in: .month, for: start)!
        let end = cal.date(byAdding: .day, value: range.count - 1, to: start)!
        return (start, end)
    }
}
