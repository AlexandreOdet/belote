//
//  BelotePlayableCardServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct BelotePlayableCardServiceTests {

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
}
