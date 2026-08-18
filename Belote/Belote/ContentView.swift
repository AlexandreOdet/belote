//
//  ContentView.swift
//  Belote
//
//  Created by Alexandre Odet on 30/07/2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultBeloteContractRaw") private var defaultBeloteContractRaw = BeloteSuit.hearts.rawValue
    @State private var selectedMatch: BeloteMatch?
    @State private var isShowingNewMatch = false

    var body: some View {
        NavigationSplitView {
            MatchListView(
                selectedMatch: $selectedMatch,
                defaultBeloteContractRaw: $defaultBeloteContractRaw,
                onNewMatch: showNewMatch
            )
        } detail: {
            if let selectedMatch {
                MatchDetailView(match: selectedMatch, defaultGameMode: defaultGameMode)
            } else {
                ContentUnavailableView(
                    "Sélectionne une partie",
                    systemImage: "rectangle.grid.1x2",
                    description: Text("Les scores et les manches apparaîtront ici.")
                )
            }
        }
        .sheet(isPresented: $isShowingNewMatch) {
            NewMatchView { match in
                modelContext.insert(match)
                selectedMatch = match
            }
        }
    }

    private var defaultGameMode: BeloteGameMode {
        .standard(contract: BeloteSuit(rawValue: defaultBeloteContractRaw) ?? .hearts)
    }

    private func showNewMatch() {
        isShowingNewMatch = true
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BeloteMatch.self, BeloteRound.self], inMemory: true)
}
