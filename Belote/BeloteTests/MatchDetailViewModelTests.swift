//
//  MatchDetailViewModelTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct MatchDetailViewModelTests {

    @MainActor
    @Test func matchDetailViewModelStartsDealFromNextDealer() {
        let dealService = StandardBeloteDealService()
        var viewModel = MatchDetailViewModel()

        viewModel.startDeal(
            nextDealerSeat: .teamAPlayerOne,
            defaultGameMode: .standard(contract: .hearts),
            dealService: dealService
        )

        #expect(viewModel.initialDeal?.dealerSeat == .teamAPlayerOne)
        #expect(viewModel.completedDeal == nil)
        #expect(viewModel.playSession == nil)
        #expect(viewModel.selectedTakingRound == .firstRound)
        #expect(viewModel.selectedTakerSeat == .teamBPlayerOne)
        #expect(viewModel.dealStatus == nil)
    }

    @MainActor
    @Test func matchDetailViewModelCompletesDealAndStartsPlaySession() {
        let dealService = StandardBeloteDealService()
        let roundPlayService = StandardBeloteRoundPlayService()
        var viewModel = MatchDetailViewModel()

        viewModel.startDeal(
            nextDealerSeat: .teamAPlayerOne,
            defaultGameMode: .standard(contract: .hearts),
            dealService: dealService
        )
        viewModel.selectedTakerSeat = .teamBPlayerOne
        viewModel.completeDeal(dealService: dealService, roundPlayService: roundPlayService)

        #expect(viewModel.completedDeal?.takerSeat == .teamBPlayerOne)
        #expect(viewModel.playSession?.currentSeat == .teamBPlayerOne)
        #expect(viewModel.dealStatus == nil)
    }

    @MainActor
    @Test func matchDetailViewModelKeepsPlaySessionWhenIllegalCardIsPlayed() throws {
        let roundPlayService = StandardBeloteRoundPlayService()
        let cardValues = StandardBeloteCardValueService()
        let trickResolver = StandardBeloteTrickResolvingService()
        let playableCards = StandardBelotePlayableCardService()
        let deal = BeloteCompletedDeal(
            dealerSeat: .teamBPlayerTwo,
            takerSeat: .teamAPlayerOne,
            trump: .hearts,
            turnedCard: card(.hearts, .seven),
            hands: [
                BeloteHand(seat: .teamAPlayerOne, cards: [card(.clubs, .ace)]),
                BeloteHand(seat: .teamBPlayerOne, cards: [card(.clubs, .seven), card(.hearts, .jack)]),
                BeloteHand(seat: .teamAPlayerTwo, cards: []),
                BeloteHand(seat: .teamBPlayerTwo, cards: [])
            ]
        )
        var session = roundPlayService.startSession(from: deal)
        session = try roundPlayService.play(
            card: card(.clubs, .ace),
            for: .teamAPlayerOne,
            in: session,
            cardValueService: cardValues,
            trickResolvingService: trickResolver,
            playableCardService: playableCards
        )
        var viewModel = MatchDetailViewModel()
        viewModel.playSession = session

        viewModel.playCard(
            seat: .teamBPlayerOne,
            card: card(.hearts, .jack),
            cardValueService: cardValues,
            trickResolvingService: trickResolver,
            playableCardService: playableCards,
            roundPlayService: roundPlayService
        )

        #expect(viewModel.playSession == session)
        #expect(viewModel.playErrorMessage == "Cette carte ne respecte pas les règles du pli.")
    }

    @MainActor
    @Test func matchDetailViewModelDoesNotCreateRoundBeforeSessionIsComplete() {
        let roundPlayService = StandardBeloteRoundPlayService()
        let scoringService = StandardBeloteRoundScoringService()
        var viewModel = MatchDetailViewModel()
        viewModel.playSession = roundPlayService.startSession(from: sampleCompletedDeal())

        let round = viewModel.makeRoundFromCompletedSession(scoringService: scoringService)

        #expect(round == nil)
        #expect(viewModel.playSession != nil)
        #expect(viewModel.roundFinalizationStatus == "La manche doit etre terminee avant validation.")
    }

    @MainActor
    @Test func matchDetailViewModelRestoresRoundPlaySession() {
        let session = StandardBeloteRoundPlayService().startSession(from: sampleCompletedDeal())
        var viewModel = MatchDetailViewModel()

        viewModel.restore(session: session)

        #expect(viewModel.completedDeal == session.completedDeal)
        #expect(viewModel.playSession == session)
        #expect(viewModel.roundFinalizationStatus == "Manche en cours restauree.")
    }

    @MainActor
    @Test func matchDetailViewModelCreatesRoundFromCompletedSessionAndClearsPlayState() throws {
        let roundPlayService = StandardBeloteRoundPlayService()
        let cardValues = StandardBeloteCardValueService()
        let trickResolver = StandardBeloteTrickResolvingService()
        let playableCards = StandardBelotePlayableCardService()
        let scoringService = StandardBeloteRoundScoringService()
        var session = roundPlayService.startSession(from: sampleCompletedDeal())

        while !session.isComplete {
            let seat = session.currentSeat
            let hand = session.hand(for: seat)
            let card = playableCards.playableCards(
                in: hand,
                for: seat,
                currentTrick: session.currentTrick,
                mode: .standard(contract: session.completedDeal.trump),
                cardValueService: cardValues
            )[0]
            session = try roundPlayService.play(
                card: card,
                for: seat,
                in: session,
                cardValueService: cardValues,
                trickResolvingService: trickResolver,
                playableCardService: playableCards
            )
        }

        var viewModel = MatchDetailViewModel()
        viewModel.playSession = session
        let round = viewModel.makeRoundFromCompletedSession(scoringService: scoringService)

        #expect(round?.trickPointsTeamA == session.teamATrickPoints)
        #expect(round?.trickPointsTeamB == session.teamBTrickPoints)
        #expect((round?.teamAPoints ?? 0) + (round?.teamBPoints ?? 0) >= 162)
        #expect(round?.dealerSeat == session.completedDeal.dealerSeat)
        #expect(round?.takerTeam == session.completedDeal.takerTeam)
        #expect(round?.trumpSuit == session.completedDeal.trump)
        #expect(viewModel.initialDeal == nil)
        #expect(viewModel.completedDeal == nil)
        #expect(viewModel.playSession == nil)
        #expect(viewModel.roundFinalizationStatus == "Manche ajoutee au score.")
    }

    @MainActor
    @Test func matchDetailViewModelScoresBeloteWhenCreatingRoundFromCompletedSession() {
        let scoringService = StandardBeloteRoundScoringService()
        var viewModel = MatchDetailViewModel()
        viewModel.playSession = BeloteRoundPlaySession(
            completedDeal: BeloteCompletedDeal(
                dealerSeat: .teamBPlayerTwo,
                takerSeat: .teamAPlayerOne,
                trump: .hearts,
                turnedCard: card(.hearts, .seven),
                hands: []
            ),
            hands: [],
            currentLeaderSeat: .teamAPlayerOne,
            currentSeat: .teamAPlayerOne,
            currentPlayedCards: [],
            completedTricks: completedTricks(winningTeams: [.teamA, .teamB, .teamA, .teamB, .teamA, .teamB, .teamA, .teamB]),
            teamATrickPoints: 90,
            teamBTrickPoints: 72,
            beloteTeam: .teamA
        )

        let round = viewModel.makeRoundFromCompletedSession(scoringService: scoringService)

        #expect(round?.beloteTeam == .teamA)
        #expect(round?.teamAPoints == 110)
        #expect(round?.teamBPoints == 72)
    }
}

private func completedTricks(winningTeams: [BeloteTeam]) -> [BeloteCompletedTrick] {
    winningTeams.enumerated().map { index, team in
        let winningSeat: BelotePlayerSeat = team == .teamA ? .teamAPlayerOne : .teamBPlayerOne
        return BeloteCompletedTrick(
            index: index + 1,
            trick: BeloteTrick(leaderSeat: winningSeat),
            result: BeloteTrickResult(
                winningSeat: winningSeat,
                winningTeam: team,
                points: 0,
                leadingSuit: .clubs
            )
        )
    }
}
