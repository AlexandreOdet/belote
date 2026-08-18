//
//  MatchDetailView.swift
//  Belote
//
//  Created by Alexandre Odet on 06/08/2026.
//

import SwiftData
import SwiftUI

struct MatchDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.beloteDependencies) private var dependencies
    @Bindable var match: BeloteMatch
    let defaultGameMode: BeloteGameMode
    @State private var isShowingNewRound = false
    @State private var isShowingCardReference = false
    @State private var selectedTakingRound = TakingRoundOption.firstRound
    @State private var selectedTakerSeat = BelotePlayerSeat.teamAPlayerOne
    @State private var selectedDealTrump = BeloteSuit.hearts
    @State private var initialDeal: BeloteInitialDeal?
    @State private var completedDeal: BeloteCompletedDeal?
    @State private var dealStatus: String?
    @State private var playSession: BeloteRoundPlaySession?
    @State private var playErrorMessage: String?
    @State private var shareStatus: String?

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ScoreCard(name: match.teamAName, score: match.teamAScore)
                        ScoreCard(name: match.teamBName, score: match.teamBScore)
                    }

                    if let winningTeam = match.winningTeam {
                        Label("\(match.displayName(for: winningTeam)) gagne la partie", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                    } else {
                        ProgressView(value: Double(max(match.teamAScore, match.teamBScore)), total: Double(match.targetScore))
                    }

                    Label("Prochain donneur: \(match.displayName(for: match.nextDealerSeat))", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Partage") {
                LabeledContent("Code", value: match.inviteCode)
                Button {
                    exportSnapshot()
                } label: {
                    Label("Exporter JSON", systemImage: "square.and.arrow.up")
                }
                Button {
                    importSnapshotCopy()
                } label: {
                    Label("Importer une copie", systemImage: "square.and.arrow.down")
                }
                if let shareStatus {
                    Text(shareStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            DealSectionView(
                match: match,
                initialDeal: initialDeal,
                completedDeal: completedDeal,
                selectedTakingRound: $selectedTakingRound,
                selectedTakerSeat: $selectedTakerSeat,
                selectedTrump: $selectedDealTrump,
                onStartDeal: startDeal,
                onCompleteDeal: completeDeal
            )
            if let dealStatus {
                Text(dealStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let playSession {
                RoundPlaySectionView(
                    match: match,
                    session: playSession,
                    cardValueService: dependencies.cardValueService,
                    playableCardService: dependencies.playableCardService,
                    errorMessage: playErrorMessage,
                    onPlayCard: playCard
                )
            }

            Section("Manches") {
                if match.sortedRounds.isEmpty {
                    Text("Aucune manche saisie.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(match.sortedRounds) { round in
                        RoundRow(match: match, round: round)
                    }
                    .onDelete(perform: deleteRounds)
                }
            }
        }
        .navigationTitle("\(match.teamAName) vs \(match.teamBName)")
        .toolbar {
            ToolbarItem(placement: cardReferenceButtonPlacement) {
                Button {
                    isShowingCardReference = true
                } label: {
                    Label("Cartes", systemImage: "rectangle.grid.3x2")
                }
            }
            ToolbarItem(placement: addButtonPlacement) {
                Button {
                    isShowingNewRound = true
                } label: {
                    Label("Ajouter une manche", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingNewRound) {
            NewRoundView(match: match, defaultGameMode: defaultGameMode) { round in
                match.rounds.append(round)
            }
        }
        .sheet(isPresented: $isShowingCardReference) {
            CardReferenceView(defaultGameMode: defaultGameMode)
        }
        .onAppear {
            selectedDealTrump = defaultGameMode.contract
            selectedTakerSeat = match.nextDealerSeat.next
        }
    }

    private var addButtonPlacement: ToolbarItemPlacement {
#if os(iOS)
        .navigationBarTrailing
#else
        .primaryAction
#endif
    }

    private var cardReferenceButtonPlacement: ToolbarItemPlacement {
#if os(iOS)
        .navigationBarLeading
#else
        .automatic
#endif
    }

    private func deleteRounds(offsets: IndexSet) {
        let rounds = match.sortedRounds

        withAnimation {
            for index in offsets {
                modelContext.delete(rounds[index])
            }
        }
    }

    private func exportSnapshot() {
        do {
            let snapshot = dependencies.matchSharingService.snapshot(for: match)
            let data = try dependencies.matchSharingService.encode(snapshot)
            shareStatus = "\(data.count) octets prêts à partager"
        } catch {
            shareStatus = error.localizedDescription
        }
    }

    private func importSnapshotCopy() {
        do {
            let snapshot = dependencies.matchSharingService.snapshot(for: match)
            let data = try dependencies.matchSharingService.encode(snapshot)
            let decoded = try dependencies.matchSharingService.decodeSnapshot(from: data)
            let importedMatch = try dependencies.matchSharingService.makeMatch(from: decoded)
            modelContext.insert(importedMatch)
            shareStatus = "Copie importée depuis JSON"
        } catch {
            shareStatus = error.localizedDescription
        }
    }

    private func startDeal() {
        let deal = dependencies.dealService.startDeal(dealerSeat: match.nextDealerSeat)
        initialDeal = deal
        completedDeal = nil
        playSession = nil
        playErrorMessage = nil
        selectedTakingRound = .firstRound
        selectedTakerSeat = match.nextDealerSeat.next
        selectedDealTrump = availableSecondRoundTrumps(for: deal).first ?? defaultGameMode.contract
        dealStatus = nil
    }

    private func completeDeal() {
        guard let initialDeal else {
            dealStatus = "Distribue d'abord les 5 cartes et la retourne."
            return
        }

        let selection: BeloteContractSelection
        switch selectedTakingRound {
        case .firstRound:
            selection = .firstRound(takerSeat: selectedTakerSeat)
        case .secondRound:
            selection = .secondRound(takerSeat: selectedTakerSeat, trump: selectedDealTrump)
        }

        do {
            let deal = try dependencies.dealService.completeDeal(initialDeal, selection: selection)
            completedDeal = deal
            playSession = dependencies.roundPlayService.startSession(from: deal)
            playErrorMessage = nil
            dealStatus = nil
        } catch {
            dealStatus = error.localizedDescription
        }
    }

    private func availableSecondRoundTrumps(for deal: BeloteInitialDeal) -> [BeloteSuit] {
        BeloteSuit.allCases.filter { suit in
            suit.cardSuit != nil && suit != deal.proposedTrump
        }
    }

    private func playCard(seat: BelotePlayerSeat, card: BeloteCard) {
        guard let playSession else {
            return
        }

        do {
            self.playSession = try dependencies.roundPlayService.play(
                card: card,
                for: seat,
                in: playSession,
                cardValueService: dependencies.cardValueService,
                trickResolvingService: dependencies.trickResolvingService,
                playableCardService: dependencies.playableCardService
            )
            playErrorMessage = nil
        } catch {
            playErrorMessage = error.localizedDescription
        }
    }
}

struct ScoreCard: View {
    let name: String
    let score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("\(score)")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct RoundRow: View {
    let match: BeloteMatch
    let round: BeloteRound

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(match.teamAName) \(round.teamAPoints)")
                Spacer()
                Text("\(round.teamBPoints) \(match.teamBName)")
            }
            .font(.headline)

            HStack {
                Label(round.trumpSuit.title, systemImage: round.trumpSuit.symbol)
                Text(round.outcome.title)
                Text(match.displayName(for: round.takerTeam))
                Text("Donneur: \(match.displayName(for: round.dealerSeat))")
                if let beloteTeam = round.beloteTeam {
                    Label("Belote \(match.displayName(for: beloteTeam))", systemImage: "suit.heart.fill")
                }
                if !round.note.isEmpty {
                    Text(round.note)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
