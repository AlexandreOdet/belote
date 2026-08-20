//
//  BeloteCardValueServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct BeloteCardValueServiceTests {

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
}
