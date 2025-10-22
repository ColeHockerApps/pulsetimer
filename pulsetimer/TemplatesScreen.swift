//
//  TemplatesScreen.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public struct TemplatesScreen: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @StateObject private var vm = TemplatesVM()

    @State private var showExerciseEditor: Bool = false
    @State private var showIntervalEditor: Bool = false

    public init() {}

    public var body: some View {
        let th = themeManager

        NavigationStack {
            List {

                // MARK: - Exercise Templates
                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        SectionHeaderView(icon: "square.on.square", title: "Exercise Templates")

                        if vm.exerciseTemplates.isEmpty {
                            HStack {
                                Image(systemName: "tray")
                                    .foregroundStyle(th.colors.textSecondary)
                                Text("No exercise templates")
                                    .foregroundStyle(th.colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(vm.exerciseTemplates) { tpl in
                                ExerciseTemplateRow(
                                    template: tpl,
                                    onEdit: {
                                        vm.beginEditExercise(template: tpl)
                                        showExerciseEditor = true
                                        haptics.tap()
                                    },
                                    onDuplicate: {
                                        vm.duplicateExerciseTemplate(id: tpl.id)
                                        haptics.play(.light)
                                    },
                                    onDelete: {
                                        vm.deleteExerciseTemplate(id: tpl.id)
                                        haptics.reject()
                                    }
                                )
                                .listRowBackground(th.colors.card)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        vm.deleteExerciseTemplate(id: tpl.id)
                                        haptics.reject()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        vm.duplicateExerciseTemplate(id: tpl.id)
                                        haptics.play(.light)
                                    } label: {
                                        Label("Duplicate", systemImage: "plus.square.on.square")
                                    }
                                }
                            }
                        }

                        PrimaryButton(title: "New Exercise Template") {
                            vm.beginCreateExercise()
                            showExerciseEditor = true
                            haptics.play(.medium)
                        }
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }

                // MARK: - Interval Presets
                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        SectionHeaderView(icon: themeManager.icons.interval, title: "Interval Presets")

                        if vm.intervalPresets.isEmpty {
                            HStack {
                                Image(systemName: "tray")
                                    .foregroundStyle(th.colors.textSecondary)
                                Text("No interval presets")
                                    .foregroundStyle(th.colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(vm.intervalPresets) { p in
                                IntervalPresetRow(
                                    preset: p,
                                    onEdit: {
                                        vm.beginEditInterval(preset: p)
                                        showIntervalEditor = true
                                        haptics.tap()
                                    },
                                    onDelete: {
                                        vm.deleteIntervalPreset(id: p.id)
                                        haptics.reject()
                                    }
                                )
                                .listRowBackground(th.colors.card)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        vm.deleteIntervalPreset(id: p.id)
                                        haptics.reject()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        PrimaryButton(title: "New Interval Preset") {
                            vm.beginCreateInterval()
                            showIntervalEditor = true
                            haptics.play(.medium)
                        }
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 10)
            .scrollContentBackground(.hidden)
            .background(th.colors.background.ignoresSafeArea())
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showExerciseEditor) {
                ExerciseTemplateEditorSheet(vm: vm, isPresented: $showExerciseEditor)
                    .environmentObject(themeManager)
                    .environmentObject(haptics)
            }
            .sheet(isPresented: $showIntervalEditor) {
                IntervalPresetEditorSheet(vm: vm, isPresented: $showIntervalEditor)
                    .environmentObject(themeManager)
                    .environmentObject(haptics)
            }
        }
    }
}

// MARK: - ViewModel (local to this screen)

@MainActor
final class TemplatesVM: ObservableObject {

    @Published var exerciseTemplates: [ExerciseTemplate] = []
    @Published var intervalPresets: [IntervalPreset] = []

    // Editing buffers
    @Published var editingExercise: ExerciseTemplateEditor = .empty
    @Published var editingInterval: IntervalPresetEditor = .empty

    private let store: LocalStore
    private var bag = Set<AnyCancellable>()

    init(store: LocalStore = .shared) {
        self.store = store
        bind()
        reload()
    }

    func reload() {
        exerciseTemplates = store.allTemplates()
        intervalPresets = store.allPresets()
    }

    private func bind() {
        store.$templates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.exerciseTemplates = self?.store.allTemplates() ?? [] }
            .store(in: &bag)
        store.$intervalPresets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.intervalPresets = self?.store.allPresets() ?? [] }
            .store(in: &bag)
    }

    // MARK: - Exercise templates

    struct ExerciseTemplateEditor: Equatable {
        var id: UUID?
        var name: String
        var notes: String
        var tags: [SportTag]
        var sets: [ExerciseSet]

        static let empty = ExerciseTemplateEditor(id: nil, name: "", notes: "", tags: [], sets: [])

        var canSave: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        func materialize() -> ExerciseTemplate {
            ExerciseTemplate(
                id: id ?? UUID(),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                defaultSets: sets,
                notes: notes,
                tags: tags
            )
        }
    }

    func beginCreateExercise() { editingExercise = .empty }
    func beginEditExercise(template: ExerciseTemplate) {
        editingExercise = ExerciseTemplateEditor(
            id: template.id,
            name: template.name,
            notes: template.notes,
            tags: template.tags,
            sets: template.defaultSets
        )
    }

    func addExerciseSet(reps: Int = 10, weight: Double = 0, restSec: TimeInterval = 60) {
        var s = editingExercise.sets
        s.append(ExerciseSet(reps: max(0, reps), weight: max(0, weight), restSec: max(0, restSec)))
        editingExercise.sets = s
    }

    func updateExerciseSet(_ id: UUID, reps: Int? = nil, weight: Double? = nil, restSec: TimeInterval? = nil) {
        var s = editingExercise.sets
        guard let i = s.firstIndex(where: { $0.id == id }) else { return }
        var e = s[i]
        if let r = reps { e.reps = max(0, r) }
        if let w = weight { e.weight = max(0, w) }
        if let rest = restSec { e.restSec = max(0, rest) }
        s[i] = e
        editingExercise.sets = s
    }

    func removeExerciseSet(_ id: UUID) {
        editingExercise.sets.removeAll { $0.id == id }
    }

    func moveExerciseSet(from: IndexSet, to: Int) {
        var s = editingExercise.sets
        s.move(fromOffsets: from, toOffset: to)
        editingExercise.sets = s
    }

    func saveExerciseTemplate() {
        guard editingExercise.canSave else { return }
        let entity = editingExercise.materialize()
        store.upsert(entity)
        reload()
        editingExercise = .empty
    }

    func deleteExerciseTemplate(id: UUID) {
        store.removeTemplate(id: id)
        reload()
    }

    func duplicateExerciseTemplate(id: UUID) {
        guard let e = store.templates[id] else { return }
        var copy = e
        copy = ExerciseTemplate(
            id: UUID(),
            name: e.name + " Copy",
            defaultSets: e.defaultSets,
            notes: e.notes,
            tags: e.tags
        )
        store.upsert(copy)
        reload()
    }

    func toggleTag(_ tag: SportTag) {
        var set = Set(editingExercise.tags)
        if set.contains(tag) { set.remove(tag) } else { set.insert(tag) }
        editingExercise.tags = Array(set).sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: - Interval presets

    struct IntervalPresetEditor: Equatable {
        var id: UUID?
        var name: String
        var workSec: Double
        var restSec: Double
        var cycles: Int
        var color: Color

        static let empty = IntervalPresetEditor(id: nil, name: "", workSec: 30, restSec: 15, cycles: 8, color: .cyan)

        var canSave: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && workSec >= 1 && cycles >= 1
        }

        func materialize() -> IntervalPreset {
            IntervalPreset(
                id: id ?? UUID(),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                workSec: workSec,
                restSec: restSec,
                cycles: cycles,
                color: color
            )
        }
    }

    func beginCreateInterval() { editingInterval = .empty }
    func beginEditInterval(preset: IntervalPreset) {
        editingInterval = IntervalPresetEditor(
            id: preset.id,
            name: preset.name,
            workSec: preset.workSec,
            restSec: preset.restSec,
            cycles: preset.cycles,
            color: preset.color.color
        )
    }

    func saveIntervalPreset() {
        guard editingInterval.canSave else { return }
        let entity = editingInterval.materialize()
        store.upsert(entity)
        reload()
        editingInterval = .empty
    }

    func deleteIntervalPreset(id: UUID) {
        store.removePreset(id: id)
        reload()
    }
}

// MARK: - Rows

private struct ExerciseTemplateRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let template: ExerciseTemplate
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let th = themeManager
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(th.colors.textPrimary)
                Spacer()
                Button(action: onDuplicate) {
                    Image(systemName: "plus.square.on.square")
                }
                .buttonStyle(.plain)
                Button(action: onEdit) {
                    Image(systemName: themeManager.icons.edit)
                }
                .buttonStyle(.plain)
            }

            if !template.notes.isEmpty {
                Text(template.notes)
                    .font(.subheadline)
                    .foregroundStyle(th.colors.textSecondary)
                    .lineLimit(2)
            }

            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(template.tags, id: \.rawValue) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }
            }

            if !template.defaultSets.isEmpty {
                HStack(spacing: 10) {
                    ForEach(template.defaultSets) { s in
                        SetPill(set: s)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button("Edit", action: onEdit)
            Button("Duplicate", action: onDuplicate)
            Button("Delete", role: .destructive, action: onDelete)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(template.name), \(template.defaultSets.count) sets"))
    }
}

private struct IntervalPresetRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let preset: IntervalPreset
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let th = themeManager
        HStack(spacing: 12) {
            Circle()
                .fill(preset.color.color)
                .frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.headline)
                    .foregroundStyle(th.colors.textPrimary)
                Text("Work \(Int(preset.workSec))s • Rest \(Int(preset.restSec))s • \(preset.cycles) cycles")
                    .font(.caption)
                    .foregroundStyle(th.colors.textSecondary)
            }
            Spacer()
            Button(action: onEdit) { Image(systemName: themeManager.icons.edit) }
                .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button("Edit", action: onEdit)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}

// MARK: - Editor Sheets

private struct ExerciseTemplateEditorSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @ObservedObject var vm: TemplatesVM
    @Binding var isPresented: Bool

    var body: some View {
        let th = themeManager
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        TextField("Name", text: Binding(get: { vm.editingExercise.name }, set: { vm.editingExercise.name = $0 }))
                            .textInputAutocapitalization(.words)

                        TextField("Notes", text: Binding(get: { vm.editingExercise.notes }, set: { vm.editingExercise.notes = $0 }), axis: .vertical)
                            .lineLimit(3...6)

                        SectionHeaderView(icon: "tag.fill", title: "Tags")
                        TagChipsGrid(
                            tags: SportTag.allCases.sorted { $0.rawValue < $1.rawValue },
                            active: Set(vm.editingExercise.tags),
                            onToggle: { tag in
                                vm.toggleTag(tag)
                                haptics.tap()
                            }
                        )
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }

                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        SectionHeaderView(icon: "list.number", title: "Sets")

                        if vm.editingExercise.sets.isEmpty {
                            Button {
                                vm.addExerciseSet()
                                haptics.tap()
                            } label: {
                                Label("Add set", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(vm.editingExercise.sets) { set in
                                SetEditorRow(
                                    set: set,
                                    onChange: { reps, weight, rest in
                                        vm.updateExerciseSet(set.id, reps: reps, weight: weight, restSec: rest)
                                    },
                                    onDelete: {
                                        vm.removeExerciseSet(set.id)
                                        haptics.reject()
                                    }
                                )
                                .listRowBackground(th.colors.card)
                            }
                            .onMove { from, to in
                                vm.moveExerciseSet(from: from, to: to)
                            }

                            Button {
                                vm.addExerciseSet()
                                haptics.tap()
                            } label: {
                                Label("Add set", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 10)
            .scrollContentBackground(.hidden)
            .background(th.colors.background.ignoresSafeArea())
            .navigationTitle(vm.editingExercise.id == nil ? "New Exercise Template" : "Edit Exercise Template")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        vm.saveExerciseTemplate()
                        isPresented = false
                        haptics.confirm()
                    }.disabled(!vm.editingExercise.canSave)
                }
            }
        }
    }
}

private struct IntervalPresetEditorSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @ObservedObject var vm: TemplatesVM
    @Binding var isPresented: Bool

    var body: some View {
        let th = themeManager
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        TextField("Name", text: Binding(get: { vm.editingInterval.name }, set: { vm.editingInterval.name = $0 }))
                            .textInputAutocapitalization(.words)

                        HStack {
                            Text("Work: \(Int(vm.editingInterval.workSec))s")
                                .foregroundStyle(th.colors.textPrimary)
                            Spacer()
                            Slider(value: Binding(get: { vm.editingInterval.workSec }, set: { vm.editingInterval.workSec = $0; haptics.tap() }), in: 5...300, step: 5)
                                .tint(th.colors.accent)
                        }

                        HStack {
                            Text("Rest: \(Int(vm.editingInterval.restSec))s")
                                .foregroundStyle(th.colors.textPrimary)
                            Spacer()
                            Slider(value: Binding(get: { vm.editingInterval.restSec }, set: { vm.editingInterval.restSec = $0; haptics.tap() }), in: 0...180, step: 5)
                                .tint(th.colors.accent)
                        }

                        HStack {
                            Text("Cycles: \(vm.editingInterval.cycles)")
                                .foregroundStyle(th.colors.textPrimary)
                            Spacer()
                            Stepper("", value: Binding(get: { vm.editingInterval.cycles }, set: { vm.editingInterval.cycles = max(1, min(60, $0)); haptics.tap() }), in: 1...60)
                                .labelsHidden()
                        }

                        ColorPicker("Color", selection: Binding(get: { vm.editingInterval.color }, set: { vm.editingInterval.color = $0 }))
                            .tint(th.colors.accent)
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 10)
            .scrollContentBackground(.hidden)
            .background(th.colors.background.ignoresSafeArea())
            .navigationTitle(vm.editingInterval.id == nil ? "New Interval Preset" : "Edit Interval Preset")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        vm.saveIntervalPreset()
                        isPresented = false
                        haptics.confirm()
                    }.disabled(!vm.editingInterval.canSave)
                }
            }
        }
    }
}

// MARK: - Small shared components (local copies)

private struct SetPill: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let set: ExerciseSet
    var body: some View {
        let th = themeManager
        let text = set.weight > 0 ? "\(set.reps)×\(Int(set.weight))kg" : "\(set.reps) reps"
        return Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(th.colors.card)
            .foregroundStyle(th.colors.textPrimary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(th.colors.separator, lineWidth: 1))
    }
}

private struct TagChip: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let tag: SportTag

    var body: some View {
        let th = themeManager
        HStack(spacing: 6) {
            Image(systemName: systemFor(tag))
            Text(tag.rawValue)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tag.color.opacity(0.15))
        .foregroundStyle(tag.color)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(th.colors.separator, lineWidth: 1))
    }

    private func systemFor(_ tag: SportTag) -> String {
        switch tag {
        case .americanFootball: return "sportscourt"
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
}

private struct TagChipsGrid: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let tags: [SportTag]
    let active: Set<SportTag>
    let onToggle: (SportTag) -> Void

    var body: some View {
        let th = themeManager
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
            ForEach(tags, id: \.rawValue) { tag in
                let selected = active.contains(tag)
                Button {
                    onToggle(tag)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: systemFor(tag))
                        Text(tag.rawValue)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selected ? tag.color.opacity(0.22) : th.colors.card)
                    .foregroundStyle(selected ? tag.color : th.colors.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: th.metrics.cornerS, style: .continuous)
                            .stroke(selected ? tag.color : th.colors.separator, lineWidth: 1)
                    )
                    .cornerRadius(th.metrics.cornerS)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func systemFor(_ tag: SportTag) -> String {
        switch tag {
        case .americanFootball: return "sportscourt"
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
}

private struct SetEditorRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let set: ExerciseSet
    let onChange: (_ reps: Int, _ weight: Double, _ rest: TimeInterval) -> Void
    let onDelete: () -> Void

    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var rest: String = ""

    var body: some View {
        let th = themeManager
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Template Set")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(th.colors.textPrimary)
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                LabeledNumberField(title: "Reps", text: $reps, width: 70)
                LabeledNumberField(title: "Weight", text: $weight, width: 90)
                LabeledNumberField(title: "Rest(s)", text: $rest, width: 90)
            }
        }
        .onAppear {
            reps = "\(set.reps)"
            weight = set.weight > 0 ? String(format: "%.0f", set.weight) : "0"
            rest = "\(Int(set.restSec))"
        }
        .onChange(of: reps) { _ in emit() }
        .onChange(of: weight) { _ in emit() }
        .onChange(of: rest) { _ in emit() }
    }

    private func emit() {
        let r = Int(reps) ?? 0
        let w = Double(weight.replacingOccurrences(of: ",", with: ".")) ?? 0
        let rs = TimeInterval(Int(rest) ?? 0)
        onChange(r, w, rs)
    }
}

private struct LabeledNumberField: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    @Binding var text: String
    var width: CGFloat = 80

    var body: some View {
        let th = themeManager
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(th.colors.textSecondary)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: width)
        }
    }
}
