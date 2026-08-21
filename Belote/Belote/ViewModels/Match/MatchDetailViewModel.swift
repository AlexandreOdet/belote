//
//  MatchDetailViewModel.swift
//  Belote
//
//  Created by Alexandre Odet on 18/08/2026.
//

import Foundation

struct MatchDetailViewModel {
    var selectedTakingRound = TakingRoundOption.firstRound
    var selectedTakerSeat = BelotePlayerSeat.teamAPlayerOne
    var selectedDealTrump = BeloteSuit.hearts
    var initialDeal: BeloteInitialDeal?
    var completedDeal: BeloteCompletedDeal?
    var dealStatus: String?
    var playSession: BeloteRoundPlaySession?
    var playErrorMessage: String?
    var roundFinalizationStatus: String?
    private(set) var matchState: BeloteMatchState = .readyForDeal(dealerSeat: .teamAPlayerOne)

    mutating func configure(defaultGameMode: BeloteGameMode, nextDealerSeat: BelotePlayerSeat) {
        selectedDealTrump = defaultGameMode.contract
        selectedTakerSeat = nextDealerSeat.next
    }

    mutating func refreshState(for match: BeloteMatch, stateService: any BeloteMatchStateService) {
        matchState = stateService.state(
            for: match,
            initialDeal: initialDeal,
            completedDeal: completedDeal,
            playSession: playSession
        )
    }

    mutating func startDeal(
        nextDealerSeat: BelotePlayerSeat,
        defaultGameMode: BeloteGameMode,
        dealService: any BeloteDealService
    ) {
        let deal = dealService.startDeal(dealerSeat: nextDealerSeat)
        initialDeal = deal
        completedDeal = nil
        playSession = nil
        playErrorMessage = nil
        roundFinalizationStatus = nil
        selectedTakingRound = .firstRound
        selectedTakerSeat = nextDealerSeat.next
        selectedDealTrump = availableSecondRoundTrumps(for: deal).first ?? defaultGameMode.contract
        dealStatus = nil
    }

    mutating func completeDeal(
        dealService: any BeloteDealService,
        roundPlayService: any BeloteRoundPlayService
    ) {
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
            let deal = try dealService.completeDeal(initialDeal, selection: selection)
            completedDeal = deal
            playSession = roundPlayService.startSession(from: deal)
            playErrorMessage = nil
            roundFinalizationStatus = nil
            dealStatus = nil
        } catch {
            dealStatus = error.localizedDescription
        }
    }

    mutating func playCard(
        seat: BelotePlayerSeat,
        card: BeloteCard,
        cardValueService: any BeloteCardValueService,
        trickResolvingService: any BeloteTrickResolvingService,
        playableCardService: any BelotePlayableCardService,
        roundPlayService: any BeloteRoundPlayService
    ) {
        guard let playSession else {
            return
        }

        do {
            self.playSession = try roundPlayService.play(
                card: card,
                for: seat,
                in: playSession,
                cardValueService: cardValueService,
                trickResolvingService: trickResolvingService,
                playableCardService: playableCardService
            )
            playErrorMessage = nil
        } catch {
            playErrorMessage = error.localizedDescription
        }
    }

    mutating func restore(session: BeloteRoundPlaySession) {
        initialDeal = nil
        completedDeal = session.completedDeal
        playSession = session
        playErrorMessage = nil
        dealStatus = nil
        roundFinalizationStatus = "Manche en cours restauree."
    }

    mutating func makeRoundFromCompletedSession(
        scoringService: any BeloteRoundScoringService
    ) -> BeloteRound? {
        guard let session = playSession else {
            roundFinalizationStatus = "Aucune manche en cours."
            return nil
        }

        guard session.isComplete else {
            roundFinalizationStatus = "La manche doit etre terminee avant validation."
            return nil
        }

        let tookAllTricksTeam = tookAllTricksTeam(in: session)
        let input = BeloteRoundScoreInput(
            takerTeam: session.completedDeal.takerTeam,
            trickPointsTeamA: session.teamATrickPoints,
            trickPointsTeamB: session.teamBTrickPoints,
            beloteTeam: session.beloteTeam,
            tookAllTricksTeam: tookAllTricksTeam
        )

        do {
            let result = try scoringService.scoreRound(input)
            let round = BeloteRound(
                trickPointsTeamA: session.teamATrickPoints,
                trickPointsTeamB: session.teamBTrickPoints,
                teamAPoints: result.teamAPoints,
                teamBPoints: result.teamBPoints,
                beloteTeam: session.beloteTeam,
                tookAllTricksTeam: tookAllTricksTeam,
                dealerSeat: session.completedDeal.dealerSeat,
                takerTeam: session.completedDeal.takerTeam,
                trumpSuit: session.completedDeal.trump,
                outcome: result.outcome,
                note: "Manche jouee"
            )

            resetRoundPlayState()
            roundFinalizationStatus = "Manche ajoutee au score."
            return round
        } catch {
            roundFinalizationStatus = error.localizedDescription
            return nil
        }
    }

    func availableSecondRoundTrumps(for deal: BeloteInitialDeal) -> [BeloteSuit] {
        BeloteSuit.allCases.filter { suit in
            suit.cardSuit != nil && suit != deal.proposedTrump
        }
    }

    private func tookAllTricksTeam(in session: BeloteRoundPlaySession) -> BeloteTeam? {
        guard session.completedTricks.count == 8,
              let firstTeam = session.completedTricks.first?.result.winningTeam,
              session.completedTricks.allSatisfy({ $0.result.winningTeam == firstTeam }) else {
            return nil
        }

        return firstTeam
    }

    private mutating func resetRoundPlayState() {
        initialDeal = nil
        completedDeal = nil
        playSession = nil
        playErrorMessage = nil
        dealStatus = nil
    }
}
