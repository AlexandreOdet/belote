//
//  MatchListView.swift
//  Belote
//
//  Created by Alexandre Odet on 06/08/2026.
//

import SwiftData
import SwiftUI

struct MatchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BeloteMatch.createdAt, order: .reverse) private var matches: [BeloteMatch]
    @Binding var selectedMatch: BeloteMatch?
    @Binding var defaultBeloteContractRaw: String
    let onNewMatch: () -> Void

    var body: some View {
        List(selection: $selectedMatch) {
            Section("Mode par defaut") {
                Picker("Atout", selection: $defaultBeloteContractRaw) {
                    ForEach(BeloteSuit.allCases) { suit in
                        Label(suit.title, systemImage: suit.symbol)
                            .tag(suit.rawValue)
                    }
                }
            }

            Section("Parties") {
                if matches.isEmpty {
                    Text("Aucune partie créée.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(matches) { match in
                        MatchRow(match: match)
                            .tag(match)
                    }
                    .onDelete(perform: deleteMatches)
                }
            }
        }
        .navigationTitle("Belote")
        .overlay {
            if matches.isEmpty {
                ContentUnavailableView {
                    Label("Aucune partie", systemImage: "suit.club")
                } description: {
                    Text("Crée une partie pour commencer à suivre les scores.")
                } actions: {
                    Button {
                        onNewMatch()
                    } label: {
                        Label("Nouvelle partie", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: addButtonPlacement) {
                Button {
                    onNewMatch()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Nouvelle partie")
            }
        }
    }

    private var addButtonPlacement: ToolbarItemPlacement {
#if os(iOS)
        .navigationBarTrailing
#else
        .primaryAction
#endif
    }

    private func deleteMatches(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                if selectedMatch == matches[index] {
                    selectedMatch = nil
                }

                modelContext.delete(matches[index])
            }
        }
    }
}

struct MatchRow: View {
    let match: BeloteMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(match.teamAName) vs \(match.teamBName)")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if let winningTeam = match.winningTeam {
                    Text(match.displayName(for: winningTeam))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: 12) {
                ScorePill(name: match.teamAName, score: match.teamAScore)
                ScorePill(name: match.teamBName, score: match.teamBScore)
            }
        }
        .padding(.vertical, 6)
    }
}

struct ScorePill: View {
    let name: String
    let score: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .lineLimit(1)
            Text("\(score)")
                .fontWeight(.semibold)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
