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
    let onJoinMatch: () -> Void

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
                    HStack {
                        Button {
                            onNewMatch()
                        } label: {
                            Label("Nouvelle partie", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("new-match-empty-button")

                        Button {
                            onJoinMatch()
                        } label: {
                            Label("Rejoindre", systemImage: "qrcode.viewfinder")
                        }
                        .accessibilityIdentifier("join-match-empty-button")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: joinButtonPlacement) {
                Button {
                    onJoinMatch()
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                }
                .help("Rejoindre une partie")
                .accessibilityIdentifier("join-match-toolbar-button")
            }
            ToolbarItem(placement: addButtonPlacement) {
                Button {
                    onNewMatch()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Nouvelle partie")
                .accessibilityIdentifier("new-match-toolbar-button")
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

    private var joinButtonPlacement: ToolbarItemPlacement {
#if os(iOS)
        .navigationBarLeading
#else
        .automatic
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(match.teamAName) vs \(match.teamBName)")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if let winningTeam = match.winningTeam {
                    Label(match.displayName(for: winningTeam), systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ScorePill(name: match.teamAName, score: match.teamAScore)
                    ScorePill(name: match.teamBName, score: match.teamBScore)
                }

                ProgressView(value: Double(max(match.teamAScore, match.teamBScore)), total: Double(match.targetScore))
                    .tint(match.teamAScore >= match.teamBScore ? .blue : .orange)
            }

            HStack {
                Label("\(match.sortedRounds.count) manches", systemImage: "list.number")
                Spacer()
                Label(match.displayName(for: match.nextDealerSeat), systemImage: "arrow.triangle.2.circlepath")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
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
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.secondary.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
