//
//  BeloteTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 30/07/2026.
//

import Foundation
import Testing
@testable import Belote

struct BeloteTests {

    @Test func roundTotalWithoutBeloteIsValidAt162Points() {
        #expect(BeloteScoring.roundTotal(hasBelote: false) == 162)
        #expect(BeloteScoring.isRoundTotalValid(teamAPoints: 82, teamBPoints: 80, hasBelote: false))
        #expect(!BeloteScoring.isRoundTotalValid(teamAPoints: 90, teamBPoints: 80, hasBelote: false))
    }

    @Test func roundTotalWithBeloteIncludesBonus() {
        #expect(BeloteScoring.roundTotal(hasBelote: true) == 182)
        #expect(BeloteScoring.isRoundTotalValid(teamAPoints: 102, teamBPoints: 80, hasBelote: true))
    }

    @Test func winningTeamRequiresTargetAndLead() {
        #expect(BeloteScoring.winningTeam(teamAScore: 990, teamBScore: 850, targetScore: 1_000) == nil)
        #expect(BeloteScoring.winningTeam(teamAScore: 1_020, teamBScore: 940, targetScore: 1_000) == .teamA)
        #expect(BeloteScoring.winningTeam(teamAScore: 1_020, teamBScore: 1_080, targetScore: 1_000) == .teamB)
        #expect(BeloteScoring.winningTeam(teamAScore: 1_020, teamBScore: 1_020, targetScore: 1_000) == nil)
    }

    @Test func dealerRotatesAfterEachRound() {
        let match = BeloteMatch(firstDealerSeat: .teamBPlayerOne)

        #expect(match.nextDealerSeat == .teamBPlayerOne)

        match.rounds.append(BeloteRound(teamAPoints: 82, teamBPoints: 80, dealerSeat: match.nextDealerSeat))
        #expect(match.nextDealerSeat == .teamAPlayerTwo)

        match.rounds.append(BeloteRound(teamAPoints: 90, teamBPoints: 72, dealerSeat: match.nextDealerSeat))
        #expect(match.nextDealerSeat == .teamBPlayerTwo)
    }

    @Test func deckContainsThirtyTwoCards() {
        #expect(BeloteDeck.cards.count == 32)
        #expect(Set(BeloteDeck.cards).count == 32)
    }

    @Test func trumpCardsUseBeloteValuesAndPower() {
        let service = StandardBeloteCardValueService()
        let mode = BeloteGameMode.standard(contract: .hearts)
        let jackOfHearts = BeloteCard(suit: .hearts, rank: .jack)
        let nineOfHearts = BeloteCard(suit: .hearts, rank: .nine)
        let aceOfHearts = BeloteCard(suit: .hearts, rank: .ace)
        let jackOfSpades = BeloteCard(suit: .spades, rank: .jack)

        #expect(service.value(of: jackOfHearts, in: mode) == 20)
        #expect(service.value(of: nineOfHearts, in: mode) == 14)
        #expect(service.value(of: aceOfHearts, in: mode) == 11)
        #expect(service.value(of: jackOfSpades, in: mode) == 2)
        #expect(service.power(of: jackOfHearts, in: mode) > service.power(of: nineOfHearts, in: mode))
    }

    @Test func cardPointTotalsMatchContractVariant() {
        let service = StandardBeloteCardValueService()

        #expect(service.cardPointsTotal(in: .standard(contract: .hearts)) == 152)
        #expect(service.cardPointsTotal(in: .standard(contract: .noTrump)) == 152)
        #expect(service.cardPointsTotal(in: .standard(contract: .allTrump)) == 248)
    }

    @Test func cardValueServiceOrdersCardsForSelectedGameMode() {
        let service = StandardBeloteCardValueService()
        let heartsAtTrump = service.cards(in: .hearts, mode: .standard(contract: .hearts))
        let heartsNoTrump = service.cards(in: .hearts, mode: .standard(contract: .noTrump))

        #expect(heartsAtTrump.first?.rank == .jack)
        #expect(heartsNoTrump.first?.rank == .ace)
    }

    @Test func scoringServiceKeepsPointsWhenContractIsMade() throws {
        let service = StandardBeloteRoundScoringService()
        let result = try service.scoreRound(
            BeloteRoundScoreInput(
                takerTeam: .teamA,
                trickPointsTeamA: 90,
                trickPointsTeamB: 72,
                beloteTeam: nil,
                tookAllTricksTeam: nil
            )
        )

        #expect(result.outcome == .contractMade)
        #expect(result.teamAPoints == 90)
        #expect(result.teamBPoints == 72)
    }

    @Test func scoringServiceGivesDefendersBasePointsWhenContractFails() throws {
        let service = StandardBeloteRoundScoringService()
        let result = try service.scoreRound(
            BeloteRoundScoreInput(
                takerTeam: .teamA,
                trickPointsTeamA: 80,
                trickPointsTeamB: 82,
                beloteTeam: nil,
                tookAllTricksTeam: nil
            )
        )

        #expect(result.outcome == .contractFailed)
        #expect(result.teamAPoints == 0)
        #expect(result.teamBPoints == 162)
    }

    @Test func scoringServiceKeepsBeloteWhenTakerFalls() throws {
        let service = StandardBeloteRoundScoringService()
        let result = try service.scoreRound(
            BeloteRoundScoreInput(
                takerTeam: .teamA,
                trickPointsTeamA: 70,
                trickPointsTeamB: 92,
                beloteTeam: .teamA,
                tookAllTricksTeam: nil
            )
        )

        #expect(result.outcome == .contractFailed)
        #expect(result.teamAPoints == 20)
        #expect(result.teamBPoints == 162)
    }

    @Test func scoringServiceScoresCapotAt252() throws {
        let service = StandardBeloteRoundScoringService()
        let result = try service.scoreRound(
            BeloteRoundScoreInput(
                takerTeam: .teamB,
                trickPointsTeamA: 162,
                trickPointsTeamB: 0,
                beloteTeam: .teamB,
                tookAllTricksTeam: .teamA
            )
        )

        #expect(result.outcome == .capotMade)
        #expect(result.teamAPoints == 252)
        #expect(result.teamBPoints == 20)
    }

    @Test func scoringServiceCanUseBeloteForContractAsConfigurableRule() throws {
        let service = StandardBeloteRoundScoringService(
            rules: BeloteRoundScoringRules(beloteCountsForContract: true)
        )
        let result = try service.scoreRound(
            BeloteRoundScoreInput(
                takerTeam: .teamA,
                trickPointsTeamA: 71,
                trickPointsTeamB: 91,
                beloteTeam: .teamA,
                tookAllTricksTeam: nil
            )
        )

        #expect(result.outcome == .litigation)
        #expect(result.teamAPoints == 20)
        #expect(result.teamBPoints == 91)
    }

    @Test func sharingServiceCreatesStableInviteCodeFromMatchID() {
        let service = StandardBeloteMatchSharingService()
        let matchID = UUID(uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF")!

        #expect(service.makeInviteCode(for: matchID) == "1234-5678")
    }

    @MainActor
    @Test func sharingServiceRoundTripsMatchSnapshotAsJSON() throws {
        let service = StandardBeloteMatchSharingService()
        let matchID = UUID(uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF")!
        let roundID = UUID(uuidString: "ABCDEF12-3456-7890-ABCD-EF1234567890")!
        let match = BeloteMatch(
            matchID: matchID,
            createdAt: Date(timeIntervalSince1970: 1_800),
            teamAName: "Nord Sud",
            teamBName: "Est Ouest",
            firstDealerSeat: .teamBPlayerOne
        )
        match.rounds.append(
            BeloteRound(
                roundID: roundID,
                createdAt: Date(timeIntervalSince1970: 2_400),
                trickPointsTeamA: 90,
                trickPointsTeamB: 72,
                teamAPoints: 90,
                teamBPoints: 72,
                dealerSeat: .teamBPlayerOne,
                takerTeam: .teamA,
                trumpSuit: .hearts,
                outcome: .contractMade
            )
        )

        let snapshot = service.snapshot(for: match)
        let data = try service.encode(snapshot)
        let decoded = try service.decodeSnapshot(from: data)

        #expect(decoded == snapshot)
        #expect(decoded.matchID == matchID)
        #expect(decoded.inviteCode == "1234-5678")
        #expect(decoded.rounds.first?.id == roundID)
    }

    @MainActor
    @Test func sharingServiceBuildsLocalMatchFromSnapshot() throws {
        let service = StandardBeloteMatchSharingService()
        let matchID = UUID(uuidString: "87654321-90AB-CDEF-1234-567890ABCDEF")!
        let source = BeloteMatch(
            matchID: matchID,
            teamAName: "Alice Bob",
            teamBName: "Chloe Dan",
            targetScore: 1_500
        )
        source.rounds.append(
            BeloteRound(
                trickPointsTeamA: 80,
                trickPointsTeamB: 82,
                teamAPoints: 0,
                teamBPoints: 162,
                dealerSeat: .teamAPlayerOne,
                takerTeam: .teamA,
                trumpSuit: .spades,
                outcome: .contractFailed,
                note: "Dedans"
            )
        )

        let imported = try service.makeMatch(from: service.snapshot(for: source))

        #expect(imported.matchID == matchID)
        #expect(imported.inviteCode == source.inviteCode)
        #expect(imported.teamAName == "Alice Bob")
        #expect(imported.targetScore == 1_500)
        #expect(imported.teamAScore == 0)
        #expect(imported.teamBScore == 162)
        #expect(imported.sortedRounds.first?.outcome == .contractFailed)
        #expect(imported.sortedRounds.first?.note == "Dedans")
    }

    @MainActor
    @Test func trickResolverLetsTrumpWinOverLeadingSuit() throws {
        let resolver = StandardBeloteTrickResolvingService()
        let cardValues = StandardBeloteCardValueService()
        let trick = BeloteTrick(
            leaderSeat: .teamAPlayerOne,
            playedCards: [
                BelotePlayedCard(seat: .teamAPlayerOne, card: BeloteCard(suit: .clubs, rank: .ace)),
                BelotePlayedCard(seat: .teamBPlayerOne, card: BeloteCard(suit: .clubs, rank: .ten)),
                BelotePlayedCard(seat: .teamAPlayerTwo, card: BeloteCard(suit: .hearts, rank: .seven)),
                BelotePlayedCard(seat: .teamBPlayerTwo, card: BeloteCard(suit: .clubs, rank: .king))
            ]
        )

        let result = try resolver.resolve(trick, mode: .standard(contract: .hearts), cardValueService: cardValues)

        #expect(result.winningSeat == .teamAPlayerTwo)
        #expect(result.winningTeam == .teamA)
        #expect(result.points == 32)
    }

    @MainActor
    @Test func trickResolverKeepsHighestLeadingSuitWhenNoTrumpIsPlayed() throws {
        let resolver = StandardBeloteTrickResolvingService()
        let cardValues = StandardBeloteCardValueService()
        let trick = BeloteTrick(
            leaderSeat: .teamBPlayerOne,
            playedCards: [
                BelotePlayedCard(seat: .teamBPlayerOne, card: BeloteCard(suit: .spades, rank: .king)),
                BelotePlayedCard(seat: .teamAPlayerTwo, card: BeloteCard(suit: .spades, rank: .ten)),
                BelotePlayedCard(seat: .teamBPlayerTwo, card: BeloteCard(suit: .diamonds, rank: .ace)),
                BelotePlayedCard(seat: .teamAPlayerOne, card: BeloteCard(suit: .spades, rank: .queen))
            ]
        )

        let result = try resolver.resolve(trick, mode: .standard(contract: .hearts), cardValueService: cardValues)

        #expect(result.winningSeat == .teamAPlayerTwo)
        #expect(result.points == 28)
    }

    @MainActor
    @Test func trickResolverUsesAllTrumpPowerForEverySuit() throws {
        let resolver = StandardBeloteTrickResolvingService()
        let cardValues = StandardBeloteCardValueService()
        let trick = BeloteTrick(
            leaderSeat: .teamAPlayerOne,
            playedCards: [
                BelotePlayedCard(seat: .teamAPlayerOne, card: BeloteCard(suit: .diamonds, rank: .nine)),
                BelotePlayedCard(seat: .teamBPlayerOne, card: BeloteCard(suit: .diamonds, rank: .ace)),
                BelotePlayedCard(seat: .teamAPlayerTwo, card: BeloteCard(suit: .diamonds, rank: .jack)),
                BelotePlayedCard(seat: .teamBPlayerTwo, card: BeloteCard(suit: .diamonds, rank: .ten))
            ]
        )

        let result = try resolver.resolve(trick, mode: .standard(contract: .allTrump), cardValueService: cardValues)

        #expect(result.winningSeat == .teamAPlayerTwo)
        #expect(result.points == 55)
    }

    @MainActor
    @Test func trickResolverRejectsIncompleteTrick() throws {
        let resolver = StandardBeloteTrickResolvingService()
        let cardValues = StandardBeloteCardValueService()
        let trick = BeloteTrick(
            leaderSeat: .teamAPlayerOne,
            playedCards: [
                BelotePlayedCard(seat: .teamAPlayerOne, card: BeloteCard(suit: .clubs, rank: .ace))
            ]
        )

        #expect(throws: BeloteTrickResolvingError.incompleteTrick(expected: 4, actual: 1)) {
            try resolver.resolve(trick, mode: .standard(contract: .hearts), cardValueService: cardValues)
        }
    }

    @MainActor
    @Test func playableCardServiceAllowsAnyCardWhenStartingTrick() {
        let service = StandardBelotePlayableCardService()
        let cardValues = StandardBeloteCardValueService()
        let hand = [
            card(.clubs, .ace),
            card(.hearts, .jack),
            card(.diamonds, .seven)
        ]

        let playableCards = service.playableCards(
            in: hand,
            for: .teamAPlayerOne,
            currentTrick: BeloteTrick(leaderSeat: .teamAPlayerOne),
            mode: .standard(contract: .hearts),
            cardValueService: cardValues
        )

        #expect(playableCards == hand)
    }

    @MainActor
    @Test func playableCardServiceRequiresLeadingSuitWhenAvailable() {
        let service = StandardBelotePlayableCardService()
        let cardValues = StandardBeloteCardValueService()
        let hand = [
            card(.clubs, .seven),
            card(.hearts, .jack),
            card(.diamonds, .ace)
        ]
        let trick = BeloteTrick(
            leaderSeat: .teamAPlayerOne,
            playedCards: [
                BelotePlayedCard(seat: .teamAPlayerOne, card: card(.clubs, .ace))
            ]
        )

        let playableCards = service.playableCards(
            in: hand,
            for: .teamBPlayerOne,
            currentTrick: trick,
            mode: .standard(contract: .hearts),
            cardValueService: cardValues
        )

        #expect(playableCards == [card(.clubs, .seven)])
    }

    @MainActor
    @Test func playableCardServiceAllowsAnyCardWhenPartnerIsWinningAndPlayerCannotFollow() {
        let service = StandardBelotePlayableCardService()
        let cardValues = StandardBeloteCardValueService()
        let hand = [
            card(.hearts, .seven),
            card(.diamonds, .ace),
            card(.spades, .king)
        ]
        let trick = BeloteTrick(
            leaderSeat: .teamAPlayerOne,
            playedCards: [
                BelotePlayedCard(seat: .teamAPlayerOne, card: card(.clubs, .ace)),
                BelotePlayedCard(seat: .teamBPlayerOne, card: card(.clubs, .ten))
            ]
        )

        let playableCards = service.playableCards(
            in: hand,
            for: .teamAPlayerTwo,
            currentTrick: trick,
            mode: .standard(contract: .hearts),
            cardValueService: cardValues
        )

        #expect(playableCards == hand)
    }

    @MainActor
    @Test func playableCardServiceRequiresTrumpWhenPlayerCannotFollowAndOpponentIsWinning() {
        let service = StandardBelotePlayableCardService()
        let cardValues = StandardBeloteCardValueService()
        let hand = [
            card(.hearts, .seven),
            card(.diamonds, .ace),
            card(.spades, .king)
        ]
        let trick = BeloteTrick(
            leaderSeat: .teamAPlayerOne,
            playedCards: [
                BelotePlayedCard(seat: .teamAPlayerOne, card: card(.clubs, .ace)),
                BelotePlayedCard(seat: .teamBPlayerOne, card: card(.clubs, .seven))
            ]
        )

        let playableCards = service.playableCards(
            in: hand,
            for: .teamBPlayerTwo,
            currentTrick: trick,
            mode: .standard(contract: .hearts),
            cardValueService: cardValues
        )

        #expect(playableCards == [card(.hearts, .seven)])
    }

    @MainActor
    @Test func playableCardServiceRequiresOvertrumpWhenPossible() {
        let service = StandardBelotePlayableCardService()
        let cardValues = StandardBeloteCardValueService()
        let hand = [
            card(.hearts, .nine),
            card(.hearts, .eight),
            card(.diamonds, .ace)
        ]
        let trick = BeloteTrick(
            leaderSeat: .teamAPlayerOne,
            playedCards: [
                BelotePlayedCard(seat: .teamAPlayerOne, card: card(.clubs, .ace)),
                BelotePlayedCard(seat: .teamBPlayerOne, card: card(.hearts, .seven))
            ]
        )

        let playableCards = service.playableCards(
            in: hand,
            for: .teamAPlayerTwo,
            currentTrick: trick,
            mode: .standard(contract: .hearts),
            cardValueService: cardValues
        )

        #expect(playableCards == [card(.hearts, .nine), card(.hearts, .eight)])
    }

    @MainActor
    @Test func roundPlayServiceRejectsCardThatDoesNotFollowSuit() throws {
        let service = StandardBeloteRoundPlayService()
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
        var session = service.startSession(from: deal)
        session = try service.play(
            card: card(.clubs, .ace),
            for: .teamAPlayerOne,
            in: session,
            cardValueService: cardValues,
            trickResolvingService: trickResolver,
            playableCardService: playableCards
        )

        #expect(throws: BeloteRoundPlayError.cardNotPlayable(card(.hearts, .jack))) {
            try service.play(
                card: card(.hearts, .jack),
                for: .teamBPlayerOne,
                in: session,
                cardValueService: cardValues,
                trickResolvingService: trickResolver,
                playableCardService: playableCards
            )
        }
    }

    @Test func dealServiceCreatesInitialDealWithTurnedCard() {
        let service = StandardBeloteDealService()
        var randomGenerator = PredictableRandomNumberGenerator()

        let deal = service.startDeal(dealerSeat: .teamAPlayerOne, randomGenerator: &randomGenerator)
        let dealtCards = deal.hands.flatMap(\.cards)

        #expect(deal.hands.count == 4)
        #expect(deal.hands.allSatisfy { $0.cards.count == 5 })
        #expect(deal.remainingDeck.count == 11)
        #expect(deal.proposedTrump == BeloteSuit(cardSuit: deal.turnedCard.suit))
        #expect(Set(dealtCards + [deal.turnedCard] + deal.remainingDeck).count == 32)
    }

    @Test func dealServiceCompletesDealWhenTurnedSuitIsTaken() throws {
        let service = StandardBeloteDealService()
        var randomGenerator = PredictableRandomNumberGenerator()

        let initialDeal = service.startDeal(dealerSeat: .teamAPlayerOne, randomGenerator: &randomGenerator)
        let completedDeal = try service.completeDeal(initialDeal, selection: .firstRound(takerSeat: .teamBPlayerOne))
        let dealtCards = completedDeal.hands.flatMap(\.cards)

        #expect(completedDeal.trump == initialDeal.proposedTrump)
        #expect(completedDeal.takerSeat == .teamBPlayerOne)
        #expect(completedDeal.hand(for: .teamBPlayerOne).contains(initialDeal.turnedCard))
        #expect(completedDeal.hands.allSatisfy { $0.cards.count == 8 })
        #expect(Set(dealtCards).count == 32)
    }

    @Test func dealServiceCompletesDealWhenSecondRoundSuitIsChosen() throws {
        let service = StandardBeloteDealService()
        var randomGenerator = PredictableRandomNumberGenerator()

        let initialDeal = service.startDeal(dealerSeat: .teamBPlayerTwo, randomGenerator: &randomGenerator)
        let chosenTrump = BeloteSuit.allCases.first { $0.cardSuit != nil && $0 != initialDeal.proposedTrump } ?? .hearts
        let completedDeal = try service.completeDeal(initialDeal, selection: .secondRound(takerSeat: .teamAPlayerOne, trump: chosenTrump))

        #expect(completedDeal.trump == chosenTrump)
        #expect(completedDeal.hand(for: .teamAPlayerOne).contains(initialDeal.turnedCard))
        #expect(completedDeal.hands.allSatisfy { $0.cards.count == 8 })
    }

    @Test func dealServiceStartsAfterDealer() {
        let service = StandardBeloteDealService()
        var randomGenerator = PredictableRandomNumberGenerator()

        let deal = service.startDeal(dealerSeat: .teamBPlayerOne, randomGenerator: &randomGenerator)

        #expect(deal.hands.map(\.seat) == [.teamAPlayerTwo, .teamBPlayerTwo, .teamAPlayerOne, .teamBPlayerOne])
    }

    @Test func dealServiceRejectsTurnedSuitAtSecondRound() throws {
        let service = StandardBeloteDealService()
        var randomGenerator = PredictableRandomNumberGenerator()
        let initialDeal = service.startDeal(dealerSeat: .teamAPlayerOne, randomGenerator: &randomGenerator)

        #expect(throws: BeloteDealError.invalidSecondRoundTrump(initialDeal.proposedTrump)) {
            try service.completeDeal(initialDeal, selection: .secondRound(takerSeat: .teamBPlayerOne, trump: initialDeal.proposedTrump))
        }
    }

    @MainActor
    @Test func roundPlayServiceRemovesPlayedCardAndAdvancesPlayer() throws {
        let deal = sampleCompletedDeal()
        let service = StandardBeloteRoundPlayService()
        let cardValues = StandardBeloteCardValueService()
        let trickResolver = StandardBeloteTrickResolvingService()
        let playableCards = StandardBelotePlayableCardService()
        let session = service.startSession(from: deal)
        let firstCard = session.hand(for: .teamBPlayerOne)[0]

        let updatedSession = try service.play(
            card: firstCard,
            for: .teamBPlayerOne,
            in: session,
            cardValueService: cardValues,
            trickResolvingService: trickResolver,
            playableCardService: playableCards
        )

        #expect(updatedSession.hand(for: .teamBPlayerOne).count == 7)
        #expect(updatedSession.currentSeat == .teamAPlayerTwo)
        #expect(updatedSession.currentPlayedCards.count == 1)
    }

    @MainActor
    @Test func roundPlayServiceResolvesCompletedTrickAndMovesLeader() throws {
        let service = StandardBeloteRoundPlayService()
        let cardValues = StandardBeloteCardValueService()
        let trickResolver = StandardBeloteTrickResolvingService()
        let playableCards = StandardBelotePlayableCardService()
        var session = service.startSession(from: sampleCompletedDeal())

        for seat in [.teamBPlayerOne, .teamAPlayerTwo, .teamBPlayerTwo, .teamAPlayerOne] as [BelotePlayerSeat] {
            let hand = session.hand(for: seat)
            let card = playableCards.playableCards(in: hand, for: seat, currentTrick: session.currentTrick, mode: .standard(contract: session.completedDeal.trump), cardValueService: cardValues)[0]
            session = try service.play(card: card, for: seat, in: session, cardValueService: cardValues, trickResolvingService: trickResolver, playableCardService: playableCards)
        }

        #expect(session.completedTricks.count == 1)
        #expect(session.currentPlayedCards.isEmpty)
        #expect(session.currentSeat == session.completedTricks[0].result.winningSeat)
        #expect(session.teamATrickPoints + session.teamBTrickPoints == session.completedTricks[0].result.points)
    }

    @MainActor
    @Test func roundPlayServiceAddsTenDeDerOnLastTrick() throws {
        let service = StandardBeloteRoundPlayService()
        let cardValues = StandardBeloteCardValueService()
        let trickResolver = StandardBeloteTrickResolvingService()
        let playableCards = StandardBelotePlayableCardService()
        var session = service.startSession(from: sampleCompletedDeal())

        while !session.isComplete {
            let seat = session.currentSeat
            let hand = session.hand(for: seat)
            let card = playableCards.playableCards(in: hand, for: seat, currentTrick: session.currentTrick, mode: .standard(contract: session.completedDeal.trump), cardValueService: cardValues)[0]
            session = try service.play(card: card, for: seat, in: session, cardValueService: cardValues, trickResolvingService: trickResolver, playableCardService: playableCards)
        }

        #expect(session.completedTricks.count == 8)
        #expect(session.teamATrickPoints + session.teamBTrickPoints == 162)
    }
}

private struct PredictableRandomNumberGenerator: RandomNumberGenerator {
    var value: UInt64 = 0

    mutating func next() -> UInt64 {
        defer { value += 1 }
        return value
    }
}

private func sampleCompletedDeal() -> BeloteCompletedDeal {
    var randomGenerator = PredictableRandomNumberGenerator()
    let dealService = StandardBeloteDealService()
    let initialDeal = dealService.startDeal(dealerSeat: .teamAPlayerOne, randomGenerator: &randomGenerator)
    return try! dealService.completeDeal(initialDeal, selection: .firstRound(takerSeat: .teamBPlayerOne))
}

private func card(_ suit: BeloteCardSuit, _ rank: BeloteCardRank) -> BeloteCard {
    BeloteCard(suit: suit, rank: rank)
}
