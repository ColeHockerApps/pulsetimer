//
//  LocalStore.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation


public final class LocalStore: ObservableObject {

    public static let shared = LocalStore()

    @Published public private(set) var exercises: [UUID: Exercise] = [:]
    @Published public private(set) var templates: [UUID: ExerciseTemplate] = [:]
    @Published public private(set) var goals: [UUID: DailyGoal] = [:]
    @Published public private(set) var intervalPresets: [UUID: IntervalPreset] = [:]
    @Published public private(set) var cardioLogs: [UUID: CardioLog] = [:]

    private var bag = Set<AnyCancellable>()
    private let ioQueue = DispatchQueue(label: "pulsetimer.localstore.io", qos: .utility)

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        loadAll()
        bindAutosave()
    }

    // MARK: - Directories

    private func baseDir() -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PulseTimer", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func file(_ name: String) -> URL {
        baseDir().appendingPathComponent(name)
    }

    // MARK: - Load / Save

    private func loadAll() {
        exercises = load("exercises.json")
        templates = load("templates.json")
        goals = load("goals.json")
        intervalPresets = load("intervalPresets.json")
        cardioLogs = load("cardioLogs.json")
    }

    private func bindAutosave() {
        $exercises.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save("exercises.json", data: self?.exercises) }
            .store(in: &bag)
        $templates.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save("templates.json", data: self?.templates) }
            .store(in: &bag)
        $goals.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save("goals.json", data: self?.goals) }
            .store(in: &bag)
        $intervalPresets.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save("intervalPresets.json", data: self?.intervalPresets) }
            .store(in: &bag)
        $cardioLogs.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save("cardioLogs.json", data: self?.cardioLogs) }
            .store(in: &bag)
    }

    private func load<T: Decodable>(_ name: String) -> [UUID: T] {
        let url = file(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return [:] }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([UUID: T].self, from: data)
        } catch {
            return [:]
        }
    }

    private func save<T: Encodable>(_ name: String, data: [UUID: T]?) {
        guard let data = data else { return }
        let url = file(name)
        ioQueue.async {
            do {
                let encoded = try self.encoder.encode(data)
                try encoded.write(to: url, options: .atomic)
            } catch {
                // ignore errors silently
            }
        }
    }

    // MARK: - CRUD

    @discardableResult
    public func upsert(_ exercise: Exercise) -> Exercise {
        exercises[exercise.id] = exercise
        return exercise
    }

    @discardableResult
    public func upsert(_ template: ExerciseTemplate) -> ExerciseTemplate {
        templates[template.id] = template
        return template
    }

    @discardableResult
    public func upsert(_ goal: DailyGoal) -> DailyGoal {
        goals[goal.id] = goal
        return goal
    }

    @discardableResult
    public func upsert(_ preset: IntervalPreset) -> IntervalPreset {
        intervalPresets[preset.id] = preset
        return preset
    }

    @discardableResult
    public func upsert(_ log: CardioLog) -> CardioLog {
        cardioLogs[log.id] = log
        return log
    }

    public func removeExercise(id: UUID) { exercises.removeValue(forKey: id) }
    public func removeTemplate(id: UUID) { templates.removeValue(forKey: id) }
    public func removeGoal(id: UUID) { goals.removeValue(forKey: id) }
    public func removePreset(id: UUID) { intervalPresets.removeValue(forKey: id) }
    public func removeCardioLog(id: UUID) { cardioLogs.removeValue(forKey: id) }

    public func allExercises(sorted: Bool = true) -> [Exercise] {
        let list = Array(exercises.values)
        return sorted ? list.sorted { $0.createdAt > $1.createdAt } : list
    }

    public func allTemplates() -> [ExerciseTemplate] {
        Array(templates.values).sorted { $0.name < $1.name }
    }

    public func allGoals(for date: Date? = nil) -> [DailyGoal] {
        let list = Array(goals.values)
        if let date {
            let key = DateUtils.startOfDay(date)
            return list.filter { DateUtils.startOfDay($0.date) == key }
        }
        return list.sorted { $0.date > $1.date }
    }

    public func allPresets() -> [IntervalPreset] {
        Array(intervalPresets.values).sorted { $0.name < $1.name }
    }

    public func allCardioLogs() -> [CardioLog] {
        Array(cardioLogs.values).sorted { $0.date > $1.date }
    }

    // MARK: - Clear

    public func resetAll() {
        exercises.removeAll()
        templates.removeAll()
        goals.removeAll()
        intervalPresets.removeAll()
        cardioLogs.removeAll()
    }
}
