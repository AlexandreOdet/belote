//
//  BeloteDealServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct BeloteDealServiceTests {

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
}
