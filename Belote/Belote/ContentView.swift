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
    @Environment(\.beloteDependencies) private var dependencies
    @AppStorage("defaultBeloteContractRaw") private var defaultBeloteContractRaw = BeloteSuit.hearts.rawValue
    @State private var selectedMatch: BeloteMatch?
    @State private var isShowingNewMatch = false
    @State private var isShowingJoinMatch = false
    @State private var pendingJoinURL: URL?

    var body: some View {
        NavigationSplitView {
            MatchListView(
                selectedMatch: $selectedMatch,
                defaultBeloteContractRaw: $defaultBeloteContractRaw,
                onNewMatch: showNewMatch,
                onJoinMatch: showJoinMatch
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
        .sheet(isPresented: $isShowingJoinMatch) {
            JoinMatchView(initialURL: pendingJoinURL) { match in
                modelContext.insert(match)
                selectedMatch = match
                pendingJoinURL = nil
            }
        }
        .onOpenURL { url in
            guard dependencies.joinLinkService.inviteCode(from: url) != nil else {
                return
            }

            pendingJoinURL = url
            isShowingJoinMatch = true
        }
    }

    private var defaultGameMode: BeloteGameMode {
        .standard(contract: BeloteSuit(rawValue: defaultBeloteContractRaw) ?? .hearts)
    }

    private func showNewMatch() {
        isShowingNewMatch = true
    }

    private func showJoinMatch() {
        pendingJoinURL = nil
        isShowingJoinMatch = true
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BeloteMatch.self, BeloteRound.self], inMemory: true)
}
