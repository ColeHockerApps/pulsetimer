//
//  ExercisesViewModel.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation


public final class ExercisesViewModel: ObservableObject {

    // MARK: - Inputs (filters & search)

    @Published public var searchQuery: String = "" {
        didSet { applyFilters() }
    }

    /// Active sport tags used as a filter (AND logic by default).
    @Published public var activeTags: Set<SportTag> = [] {
        didSet { applyFilters() }
    }

    /// Sort mode for list rendering.
    @Published public var sort: Sort = .newest {
        didSet { applyFilters() }
    }

    // MARK: - Listings

    @Published public private(set) var items: [Exercise] = []
    @Published public private(set) var templates: [ExerciseTemplate] = []

    // MARK: - Editing state

    @Published public var editing: ExerciseEditor = .empty

    public struct ExerciseEditor: Equatable {
        public var id: UUID?
        public var name: String
        public var notes: String
        public var tags: [SportTag]
        public var sets: [ExerciseSet]

        public init(id: UUID? = nil, name: String = "", notes: String = "", tags: [SportTag] = [], sets: [ExerciseSet] = []) {
            self.id = id
            self.name = name
            self.notes = notes
            self.tags = tags
            self.sets = sets
        }

        public static let empty = ExerciseEditor()
        public var isNew: Bool { id == nil }

        public var canSave: Bool {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty
        }

        public func materialize() -> Exercise {
            Exercise(
                id: id ?? UUID(),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes,
                sportTags: tags,
                sets: sets
            )
        }
    }

    // MARK: - Sort

    public enum Sort: String, CaseIterable, Identifiable {
        case newest
        case oldest
        case nameAZ
        case nameZA
        case setsCount

        public var id: String { rawValue }
    }

    // MARK: - Internals

    private let store: LocalStore
    private var bag = Set<AnyCancellable>()
    private var all: [Exercise] = []

    public init(store: LocalStore = .shared) {
        self.store = store
        bind()
        reload()
    }

    // MARK: - CRUD

    @discardableResult
    public func createEmpty() -> ExerciseEditor {
        editing = ExerciseEditor()
        return editing
    }

    @discardableResult
    public func edit(id: UUID) -> ExerciseEditor {
        guard let e = store.exercises[id] else {
            editing = .empty
            return editing
        }
        editing = ExerciseEditor(id: e.id, name: e.name, notes: e.notes, tags: e.sportTags, sets: e.sets)
        return editing
    }

    public func applyTemplate(_ template: ExerciseTemplate) {
        // Merge template into current editor (preserve edited name if present)
        if editing.isNew && editing.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            editing.name = template.name
        }
        if editing.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            editing.notes = template.notes
        }
        if editing.tags.isEmpty {
            editing.tags = template.tags
        }
        if editing.sets.isEmpty {
            editing.sets = template.defaultSets
        }
    }

    public func saveEditing() {
        guard editing.canSave else { return }
        let entity = editing.materialize()
        store.upsert(entity)
        editing = .empty
        reload()
    }

    public func delete(id: UUID) {
        store.removeExercise(id: id)
        if editing.id == id { editing = .empty }
        reload()
    }

    // MARK: - Set operations in editor

    public func addSet(reps: Int = 10, weight: Double = 0, restSec: TimeInterval = 60) {
        var sets = editing.sets
        sets.append(ExerciseSet(reps: max(0, reps), weight: max(0, weight), restSec: max(0, restSec)))
        editing.sets = sets
    }

    public func updateSet(_ setID: UUID, reps: Int? = nil, weight: Double? = nil, restSec: TimeInterval? = nil) {
        var sets = editing.sets
        guard let i = sets.firstIndex(where: { $0.id == setID }) else { return }
        var s = sets[i]
        if let r = reps { s.reps = max(0, r) }
        if let w = weight { s.weight = max(0, w) }
        if let rest = restSec { s.restSec = max(0, rest) }
        sets[i] = s
        editing.sets = sets
    }

    public func removeSet(_ setID: UUID) {
        editing.sets.removeAll { $0.id == setID }
    }

    public func moveSet(from source: IndexSet, to destination: Int) {
        var sets = editing.sets
        sets.move(fromOffsets: source, toOffset: destination)
        editing.sets = sets
    }

    // MARK: - Tag operations in editor

    public func toggleTag(_ tag: SportTag) {
        var s = Set(editing.tags)
        if s.contains(tag) { s.remove(tag) } else { s.insert(tag) }
        editing.tags = Array(s).sorted { $0.rawValue < $1.rawValue }
    }

    public func setTags(_ tags: [SportTag]) {
        editing.tags = Array(Set(tags)).sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: - Filters

    public func toggleFilterTag(_ tag: SportTag) {
        if activeTags.contains(tag) {
            activeTags.remove(tag)
        } else {
            activeTags.insert(tag)
        }
        applyFilters()
    }

    public func clearFilters() {
        activeTags.removeAll()
        searchQuery = ""
        sort = .newest
        applyFilters()
    }

    // MARK: - Reload & Bind

    public func reload() {
        all = store.allExercises(sorted: false)
        templates = store.allTemplates()
        applyFilters()
    }

    private func bind() {
        store.$exercises
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &bag)

        store.$templates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.templates = self?.store.allTemplates() ?? [] }
            .store(in: &bag)
    }

    // MARK: - Filtering + Sorting

    private func applyFilters() {
        var list = all

        if !activeTags.isEmpty {
            list = list.filter { ex in
                let s = Set(ex.sportTags)
                // AND logic: every active tag must be present
                return activeTags.allSatisfy { s.contains($0) }
            }
        }

        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter { ex in
                ex.name.lowercased().contains(q) ||
                ex.notes.lowercased().contains(q) ||
                ex.sportTags.map { $0.rawValue.lowercased() }.contains { $0.contains(q) }
            }
        }

        switch sort {
        case .newest:
            list.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            list.sort { $0.createdAt < $1.createdAt }
        case .nameAZ:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameZA:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .setsCount:
            list.sort { $0.sets.count > $1.sets.count }
        }

        items = list
    }

    // MARK: - Convenience

    public func instantiateFromTemplate(_ templateID: UUID) {
        guard let tpl = store.templates[templateID] else { return }
        let exercise = tpl.instantiate()
        store.upsert(exercise)
        reload()
    }

    public func duplicate(id: UUID) {
        guard let e = store.exercises[id] else { return }
        var copy = e
        copy = Exercise(
            id: UUID(),
            name: e.name + " Copy",
            notes: e.notes,
            sportTags: e.sportTags,
            sets: e.sets
        )
        store.upsert(copy)
        reload()
    }

    public func allTagsSorted() -> [SportTag] {
        SportTag.allCases.sorted { $0.rawValue < $1.rawValue }
    }
}
