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
    @State private var viewModel = MatchDetailViewModel()
    @State private var shareStatus: String?
    @State private var cloudInviteCode = ""
    @State private var isSyncingCloudKit = false
    @State private var isShowingQRCode = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ScoreCard(
                            name: match.teamAName,
                            score: match.teamAScore,
                            targetScore: match.targetScore,
                            isLeading: match.teamAScore >= match.teamBScore
                        )
                        ScoreCard(
                            name: match.teamBName,
                            score: match.teamBScore,
                            targetScore: match.targetScore,
                            isLeading: match.teamBScore > match.teamAScore
                        )
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

                    MatchStateBanner(match: match, state: viewModel.matchState)
                }
                .padding(.vertical, 8)
            }

            Section("Partage") {
                LabeledContent("Code", value: match.inviteCode)
                TextField("Code CloudKit", text: $cloudInviteCode)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ShareActionButton(title: "Exporter", systemImage: "square.and.arrow.up", isProminent: false) {
                        exportSnapshot()
                    }

                    ShareActionButton(title: "Copier local", systemImage: "square.and.arrow.down", isProminent: false) {
                        importSnapshotCopy()
                    }

                    ShareActionButton(title: "CloudKit", systemImage: "icloud.and.arrow.up", isProminent: true) {
                        uploadToCloudKit()
                    }
                    .disabled(isSyncingCloudKit)

                    ShareActionButton(title: "QR Code", systemImage: "qrcode", isProminent: false) {
                        isShowingQRCode = true
                    }
                    .accessibilityIdentifier("show-match-qr-code-button")
                }

                Button {
                    downloadCloudKitCopy()
                } label: {
                    Label("Importer depuis CloudKit", systemImage: "icloud.and.arrow.down")
                }
                .disabled(isSyncingCloudKit || cloudInviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let shareStatus {
                    Text(shareStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            DealSectionView(
                match: match,
                initialDeal: viewModel.initialDeal,
                completedDeal: viewModel.completedDeal,
                selectedTakingRound: $viewModel.selectedTakingRound,
                selectedTakerSeat: $viewModel.selectedTakerSeat,
                selectedTrump: $viewModel.selectedDealTrump,
                onStartDeal: startDeal,
                onCompleteDeal: completeDeal
            )
            if let dealStatus = viewModel.dealStatus {
                Text(dealStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let playSession = viewModel.playSession {
                RoundPlaySectionView(
                    match: match,
                    session: playSession,
                    cardValueService: dependencies.cardValueService,
                    playableCardService: dependencies.playableCardService,
                    errorMessage: viewModel.playErrorMessage,
                    onPlayCard: playCard,
                    onConfirmRound: confirmPlayedRound
                )
            }
            if let roundFinalizationStatus = viewModel.roundFinalizationStatus {
                Text(roundFinalizationStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .sheet(isPresented: $isShowingQRCode) {
            MatchQRCodeView(match: match, joinLinkService: dependencies.joinLinkService)
        }
        .onAppear {
            viewModel.configure(defaultGameMode: defaultGameMode, nextDealerSeat: match.nextDealerSeat)
            cloudInviteCode = match.inviteCode
            restoreActiveRoundIfNeeded()
            refreshMatchState()
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
        refreshMatchState()
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

    private func uploadToCloudKit() {
        isSyncingCloudKit = true
        shareStatus = "Synchronisation CloudKit en cours..."

        Task {
            do {
                let reference = try await dependencies.matchSyncService.upload(
                    match: match,
                    sharingService: dependencies.matchSharingService
                )
                shareStatus = "Partie synchronisee avec le code \(reference.inviteCode)"
            } catch {
                shareStatus = error.localizedDescription
            }

            isSyncingCloudKit = false
        }
    }

    private func downloadCloudKitCopy() {
        isSyncingCloudKit = true
        shareStatus = "Import CloudKit en cours..."

        Task {
            do {
                let importedMatch = try await dependencies.matchSyncService.download(
                    inviteCode: cloudInviteCode,
                    sharingService: dependencies.matchSharingService
                )
                modelContext.insert(importedMatch)
                shareStatus = "Copie importee depuis CloudKit"
            } catch {
                shareStatus = error.localizedDescription
            }

            isSyncingCloudKit = false
        }
    }

    private func startDeal() {
        viewModel.startDeal(
            nextDealerSeat: match.nextDealerSeat,
            defaultGameMode: defaultGameMode,
            dealService: dependencies.dealService
        )
        refreshMatchState()
    }

    private func completeDeal() {
        viewModel.completeDeal(
            dealService: dependencies.dealService,
            roundPlayService: dependencies.roundPlayService
        )
        saveActiveRoundIfNeeded()
        refreshMatchState()
    }

    private func playCard(seat: BelotePlayerSeat, card: BeloteCard) {
        viewModel.playCard(
            seat: seat,
            card: card,
            cardValueService: dependencies.cardValueService,
            trickResolvingService: dependencies.trickResolvingService,
            playableCardService: dependencies.playableCardService,
            roundPlayService: dependencies.roundPlayService
        )
        saveActiveRoundIfNeeded()
        refreshMatchState()
    }

    private func confirmPlayedRound() {
        guard let round = viewModel.makeRoundFromCompletedSession(scoringService: dependencies.roundScoringService) else {
            refreshMatchState()
            return
        }

        match.rounds.append(round)
        dependencies.roundPlaySessionPersistenceService.clear(in: match)
        refreshMatchState()
    }

    private func saveActiveRoundIfNeeded() {
        guard let playSession = viewModel.playSession else {
            return
        }

        do {
            try dependencies.roundPlaySessionPersistenceService.save(playSession, in: match)
        } catch {
            viewModel.roundFinalizationStatus = error.localizedDescription
        }
    }

    private func restoreActiveRoundIfNeeded() {
        guard viewModel.playSession == nil else {
            return
        }

        do {
            if let session = try dependencies.roundPlaySessionPersistenceService.load(from: match) {
                viewModel.restore(session: session)
                refreshMatchState()
            }
        } catch {
            viewModel.roundFinalizationStatus = error.localizedDescription
        }
    }

    private func refreshMatchState() {
        viewModel.refreshState(for: match, stateService: dependencies.matchStateService)
    }
}

private struct MatchStateBanner: View {
    let match: BeloteMatch
    let state: BeloteMatchState

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(state.title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: state.systemImage)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.accentColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var subtitle: String {
        switch state {
        case let .readyForDeal(dealerSeat):
            return "Donneur: \(match.displayName(for: dealerSeat))"
        case let .choosingTrump(_, turnedCard, proposedTrump):
            return "Carte tournee: \(turnedCard.title). Atout propose: \(proposedTrump.title)."
        case let .readyToPlay(takerSeat, trump):
            return "Preneur: \(match.displayName(for: takerSeat)). Atout: \(trump.title)."
        case let .playingRound(currentSeat, trickNumber, playedCardCount):
            return "Pli \(trickNumber), carte \(playedCardCount + 1): \(match.displayName(for: currentSeat)) joue."
        case let .roundReadyToScore(takerTeam, teamATrickPoints, teamBTrickPoints):
            return "\(match.displayName(for: takerTeam)) a pris. Plis: \(match.teamAName) \(teamATrickPoints), \(match.teamBName) \(teamBTrickPoints)."
        case let .matchComplete(winningTeam):
            return "\(match.displayName(for: winningTeam)) a atteint le score cible."
        }
    }
}

struct ScoreCard: View {
    let name: String
    let score: Int
    let targetScore: Int
    let isLeading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                if isLeading {
                    Image(systemName: "chevron.up.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(score)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                Text("/ \(targetScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(score), total: Double(targetScore))
                .tint(isLeading ? .green : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(isLeading ? Color.green.opacity(0.10) : Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ShareActionButton: View {
    let title: String
    let systemImage: String
    let isProminent: Bool
    let action: () -> Void

    var body: some View {
        if isProminent {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
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
