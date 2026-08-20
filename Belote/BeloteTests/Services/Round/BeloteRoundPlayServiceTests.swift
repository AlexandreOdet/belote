//
//  BeloteRoundPlayServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct BeloteRoundPlayServiceTests {

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
    @Test func roundPlayServiceDetectsBeloteRebeloteWhenTrumpKingOrQueenIsPlayed() throws {
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
                BeloteHand(seat: .teamAPlayerOne, cards: [card(.hearts, .king), card(.hearts, .queen)]),
                BeloteHand(seat: .teamBPlayerOne, cards: []),
                BeloteHand(seat: .teamAPlayerTwo, cards: []),
                BeloteHand(seat: .teamBPlayerTwo, cards: [])
            ]
        )
        let session = service.startSession(from: deal)

        let updatedSession = try service.play(
            card: card(.hearts, .king),
            for: .teamAPlayerOne,
            in: session,
            cardValueService: cardValues,
            trickResolvingService: trickResolver,
            playableCardService: playableCards
        )

        #expect(updatedSession.beloteTeam == .teamA)
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
