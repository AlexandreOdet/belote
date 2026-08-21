//
//  BeloteMatchStateServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 21/08/2026.
//

import Testing
@testable import Belote

struct BeloteMatchStateServiceTests {
    private let service = StandardBeloteMatchStateService()

    @Test func stateIsReadyForDealWhenMatchHasNoActiveRound() {
        let match = BeloteMatch(firstDealerSeat: .teamBPlayerOne)

        let state = service.state(
            for: match,
            initialDeal: nil,
            completedDeal: nil,
            playSession: nil
        )

        #expect(state == .readyForDeal(dealerSeat: .teamBPlayerOne))
    }

    @Test func stateIsChoosingTrumpWhenInitialDealExists() {
        let initialDeal = BeloteInitialDeal(
            dealerSeat: .teamAPlayerOne,
            hands: [],
            turnedCard: card(.diamonds, .queen),
            remainingDeck: []
        )

        let state = service.state(
            for: BeloteMatch(),
            initialDeal: initialDeal,
            completedDeal: nil,
            playSession: nil
        )

        #expect(state == .choosingTrump(
            dealerSeat: .teamAPlayerOne,
            turnedCard: card(.diamonds, .queen),
            proposedTrump: .diamonds
        ))
    }

    @Test func stateIsReadyToPlayWhenDealIsCompletedWithoutPlaySession() {
        let completedDeal = BeloteCompletedDeal(
            dealerSeat: .teamBPlayerTwo,
            takerSeat: .teamAPlayerOne,
            trump: .spades,
            turnedCard: card(.spades, .seven),
            hands: []
        )

        let state = service.state(
            for: BeloteMatch(),
            initialDeal: nil,
            completedDeal: completedDeal,
            playSession: nil
        )

        #expect(state == .readyToPlay(takerSeat: .teamAPlayerOne, trump: .spades))
    }

    @Test func stateIsPlayingRoundWhenPlaySessionIsInProgress() {
        let session = StandardBeloteRoundPlayService().startSession(from: sampleCompletedDeal())

        let state = service.state(
            for: BeloteMatch(),
            initialDeal: nil,
            completedDeal: session.completedDeal,
            playSession: session
        )

        #expect(state == .playingRound(currentSeat: .teamBPlayerOne, trickNumber: 1, playedCardCount: 0))
    }

    @Test func stateIsRoundReadyToScoreWhenPlaySessionIsComplete() {
        let session = BeloteRoundPlaySession(
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
            completedTricks: completedMatchStateTricks(
                winningTeams: [.teamA, .teamB, .teamA, .teamB, .teamA, .teamB, .teamA, .teamB]
            ),
            teamATrickPoints: 82,
            teamBTrickPoints: 80,
            beloteTeam: nil
        )

        let state = service.state(
            for: BeloteMatch(),
            initialDeal: nil,
            completedDeal: session.completedDeal,
            playSession: session
        )

        #expect(state == .roundReadyToScore(takerTeam: .teamA, teamATrickPoints: 82, teamBTrickPoints: 80))
    }

    @Test func stateIsMatchCompleteWhenTargetScoreIsReached() {
        let match = BeloteMatch(targetScore: 100)
        match.rounds.append(BeloteRound(trickPointsTeamA: 90, trickPointsTeamB: 72, teamAPoints: 100, teamBPoints: 62))

        let state = service.state(
            for: match,
            initialDeal: nil,
            completedDeal: nil,
            playSession: nil
        )

        #expect(state == .matchComplete(winningTeam: .teamA))
    }
}

private func completedMatchStateTricks(winningTeams: [BeloteTeam]) -> [BeloteCompletedTrick] {
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
