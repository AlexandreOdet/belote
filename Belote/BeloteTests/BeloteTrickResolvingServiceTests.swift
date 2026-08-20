//
//  BeloteTrickResolvingServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct BeloteTrickResolvingServiceTests {

    @MainActor
    @Test func trickResolverLetsTrumpWinOverLeadingSuit() throws {
        let resolver = StandardBeloteTrickResolvingService()
        let cardValues = StandardBeloteCardValueService()
        let trick = BeloteTrick(
            leaderSeat: .teamAPlayerOne,
            playedCards: [
                BelotePlayedCard(seat: .teamAPlayerOne, card: card(.clubs, .ace)),
                BelotePlayedCard(seat: .teamBPlayerOne, card: card(.clubs, .ten)),
                BelotePlayedCard(seat: .teamAPlayerTwo, card: card(.hearts, .seven)),
                BelotePlayedCard(seat: .teamBPlayerTwo, card: card(.clubs, .king))
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
                BelotePlayedCard(seat: .teamBPlayerOne, card: card(.spades, .king)),
                BelotePlayedCard(seat: .teamAPlayerTwo, card: card(.spades, .ten)),
                BelotePlayedCard(seat: .teamBPlayerTwo, card: card(.diamonds, .ace)),
                BelotePlayedCard(seat: .teamAPlayerOne, card: card(.spades, .queen))
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
                BelotePlayedCard(seat: .teamAPlayerOne, card: card(.diamonds, .nine)),
                BelotePlayedCard(seat: .teamBPlayerOne, card: card(.diamonds, .ace)),
                BelotePlayedCard(seat: .teamAPlayerTwo, card: card(.diamonds, .jack)),
                BelotePlayedCard(seat: .teamBPlayerTwo, card: card(.diamonds, .ten))
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
                BelotePlayedCard(seat: .teamAPlayerOne, card: card(.clubs, .ace))
            ]
        )

        #expect(throws: BeloteTrickResolvingError.incompleteTrick(expected: 4, actual: 1)) {
            try resolver.resolve(trick, mode: .standard(contract: .hearts), cardValueService: cardValues)
        }
    }
}
