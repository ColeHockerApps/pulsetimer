//
//  ExercisesScreen.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public struct ExercisesScreen: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @StateObject private var vm = ExercisesViewModel()

    @State private var showEditor: Bool = false
    @State private var showFilters: Bool = false

    public init() {}

    public var body: some View {
        let th = themeManager

        NavigationStack {
            ZStack {
                th.colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // <-- Only addition to force large title to render
                    Color.clear
                        .frame(height: 1)
                        .accessibilityHidden(true)

                    List {

                        // MARK: - Filters
                        if showFilters {
                            Section {
                                VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                    SectionHeaderView(icon: "line.3.horizontal.decrease.circle", title: "Filters")
                                    TagChipsGrid(
                                        tags: vm.allTagsSorted(),
                                        active: vm.activeTags,
                                        onToggle: { tag in
                                            vm.toggleFilterTag(tag)
                                            haptics.tap()
                                        }
                                    )
                                    HStack {
                                        Text("Sort")
                                            .foregroundStyle(th.colors.textSecondary)
                                        Spacer()
                                        Picker("", selection: $vm.sort) {
                                            Text("Newest").tag(ExercisesViewModel.Sort.newest)
                                            Text("Oldest").tag(ExercisesViewModel.Sort.oldest)
                                            Text("Name A–Z").tag(ExercisesViewModel.Sort.nameAZ)
                                            Text("Name Z–A").tag(ExercisesViewModel.Sort.nameZA)
                                            Text("Sets").tag(ExercisesViewModel.Sort.setsCount)
                                        }
                                        .pickerStyle(.menu)
                                        .tint(th.colors.accent)
                                    }
                                    Button(role: .none) {
                                        vm.clearFilters()
                                        haptics.play(.light)
                                    } label: {
                                        HStack {
                                            Image(systemName: "xmark.circle.fill")
                                            Text("Clear filters")
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, th.metrics.spacingM)
                                .listRowBackground(th.colors.card)
                            }
                        }

                        // MARK: - Templates quick start
                        if !vm.templates.isEmpty {
                            Section {
                                VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                                    SectionHeaderView(icon: "square.on.square", title: "Templates")
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(vm.templates) { tpl in
                                                TemplateChip(title: tpl.name) {
                                                    vm.instantiateFromTemplate(tpl.id)
                                                    haptics.confirm()
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 2)
                                    }
                                }
                                .padding(.vertical, th.metrics.spacingM)
                                .listRowBackground(th.colors.card)
                            }
                        }

                        // MARK: - List
                        Section {
                            if vm.items.isEmpty {
                                HStack {
                                    Image(systemName: "tray")
                                        .foregroundStyle(th.colors.textSecondary)
                                    Text("No exercises")
                                        .foregroundStyle(th.colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                                .listRowBackground(th.colors.card)
                            } else {
                                ForEach(vm.items) { ex in
                                    ExerciseRow(
                                        exercise: ex,
                                        onEdit: {
                                            _ = vm.edit(id: ex.id)
                                            showEditor = true
                                            haptics.tap()
                                        },
                                        onDuplicate: {
                                            vm.duplicate(id: ex.id)
                                            haptics.confirm()
                                        }
                                    )
                                    .listRowBackground(th.colors.card)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            vm.delete(id: ex.id)
                                            haptics.reject()
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button {
                                            vm.duplicate(id: ex.id)
                                            haptics.play(.light)
                                        } label: {
                                            Label("Duplicate", systemImage: "plus.square.on.square")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .environment(\.defaultMinListRowHeight, 10)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(th.colors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { showFilters.toggle() }
                        haptics.tap()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.createEmpty()
                        showEditor = true
                        haptics.play(.medium)
                    } label: {
                        Image(systemName: themeManager.icons.add)
                    }
                }
            }
            .searchable(text: Binding<String>(
                get: { vm.searchQuery },
                set: { vm.searchQuery = $0 }
            ), placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search exercises")
            .sheet(isPresented: $showEditor) {
                ExerciseEditorSheet(vm: vm, isPresented: $showEditor)
                    .environmentObject(themeManager)
                    .environmentObject(haptics)
            }
        }
    }
}

// MARK: - Row

private struct ExerciseRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let exercise: Exercise
    let onEdit: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        let th = themeManager
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text(exercise.name)
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

            if !exercise.notes.isEmpty {
                Text(exercise.notes)
                    .font(.subheadline)
                    .foregroundStyle(th.colors.textSecondary)
                    .lineLimit(2)
            }

            if !exercise.sportTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(exercise.sportTags, id: \.rawValue) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }
            }

            if !exercise.sets.isEmpty {
                HStack(spacing: 10) {
                    ForEach(exercise.sets) { s in
                        SetPill(set: s)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(exercise.name), \(exercise.sets.count) sets"))
    }
}

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

// MARK: - Editor Sheet

private struct ExerciseEditorSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    @ObservedObject var vm: ExercisesViewModel
    @Binding var isPresented: Bool

    var body: some View {
        let th = themeManager
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        TextField("Name", text: Binding(
                            get: { vm.editing.name },
                            set: { vm.editing.name = $0 }
                        ))
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)

                        TextField("Notes", text: Binding(
                            get: { vm.editing.notes },
                            set: { vm.editing.notes = $0 }
                        ), axis: .vertical)
                        .lineLimit(3...6)

                        SectionHeaderView(icon: "tag.fill", title: "Tags")
                        TagChipsGrid(
                            tags: vm.allTagsSorted(),
                            active: Set(vm.editing.tags),
                            onToggle: { tag in
                                vm.toggleTag(tag)
                                haptics.tap()
                            }
                        )
                    }
                    .padding(.vertical, th.metrics.spacingM)
                    .listRowBackground(th.colors.card)
                }

                // Sets
                Section {
                    VStack(alignment: .leading, spacing: th.metrics.spacingM) {
                        SectionHeaderView(icon: "list.number", title: "Sets")

                        if vm.editing.sets.isEmpty {
                            Button {
                                vm.addSet()
                                haptics.tap()
                            } label: {
                                Label("Add set", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(vm.editing.sets) { set in
                                SetEditorRow(
                                    set: set,
                                    onChange: { reps, weight, rest in
                                        vm.updateSet(set.id, reps: reps, weight: weight, restSec: rest)
                                    },
                                    onDelete: { vm.removeSet(set.id); haptics.reject() }
                                )
                                .listRowBackground(th.colors.card)
                            }
                            .onMove { from, to in
                                vm.moveSet(from: from, to: to)
                            }

                            Button {
                                vm.addSet()
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
            .navigationTitle(vm.editing.isNew ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        vm.saveEditing()
                        isPresented = false
                        haptics.confirm()
                    }
                    .disabled(!vm.editing.canSave)
                }
            }
        }
    }
}

// MARK: - SetEditorRow

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
                Text("Set")
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

// MARK: - TagChipsGrid (inline picker)

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

private struct TemplateChip: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let action: () -> Void

    var body: some View {
        let th = themeManager
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(th.colors.card)
                .foregroundStyle(th.colors.textPrimary)
                .overlay(RoundedRectangle(cornerRadius: th.metrics.cornerS).stroke(th.colors.separator, lineWidth: 1))
                .cornerRadius(th.metrics.cornerS)
        }
        .buttonStyle(.plain)
    }
}
