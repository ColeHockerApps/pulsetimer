//
//  TagPickerView.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

public struct TagPickerView: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var haptics: HapticsManager

    private let allTags: [SportTag]
    @Binding private var selection: Set<SportTag>
    private let allowsMultiple: Bool
    private let showsSearch: Bool
    private let onChange: ((Set<SportTag>) -> Void)?

    @State private var query: String = ""

    public init(
        tags: [SportTag] = SportTag.allCases,
        selection: Binding<Set<SportTag>>,
        allowsMultiple: Bool = true,
        showsSearch: Bool = true,
        onChange: ((Set<SportTag>) -> Void)? = nil
    ) {
        self.allTags = tags.sorted { $0.rawValue < $1.rawValue }
        self._selection = selection
        self.allowsMultiple = allowsMultiple
        self.showsSearch = showsSearch
        self.onChange = onChange
    }

    public var body: some View {
        let th = themeManager
        VStack(alignment: .leading, spacing: th.metrics.spacingM) {

            if showsSearch {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(th.colors.textSecondary)
                    TextField("Search sports", text: $query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .foregroundStyle(th.colors.textPrimary)
                        .textFieldStyle(.roundedBorder)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(th.colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Clear search"))
                    }
                }
            }

            if allowsMultiple {
                HStack(spacing: 10) {
                    Button {
                        selection = Set(filteredTags())
                        haptics.play(.light)
                        onChange?(selection)
                    } label: {
                        Label("Select All", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.plain)

                    Button {
                        selection.removeAll()
                        haptics.play(.light)
                        onChange?(selection)
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption)
                .foregroundStyle(th.colors.textSecondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                ForEach(filteredTags(), id: \.rawValue) { tag in
                    let selected = selection.contains(tag)
                    Button {
                        toggle(tag)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: systemFor(tag))
                            Text(tag.rawValue)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
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
                    .accessibilityLabel(Text("\(tag.rawValue)"))
                    .accessibilityAddTraits(selection.contains(tag) ? .isSelected : [])
                }
            }
        }
    }

    private func filteredTags() -> [SportTag] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return allTags }
        return allTags.filter { $0.rawValue.lowercased().contains(q) }
    }

    private func toggle(_ tag: SportTag) {
        if allowsMultiple {
            if selection.contains(tag) {
                selection.remove(tag)
            } else {
                selection.insert(tag)
            }
        } else {
            if selection.contains(tag) {
                selection.removeAll()
            } else {
                selection = [tag]
            }
        }
        haptics.tap()
        onChange?(selection)
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
