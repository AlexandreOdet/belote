//
//  BeloteCardTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct BeloteCardTests {

    @Test func deckContainsThirtyTwoCards() {
        #expect(BeloteDeck.cards.count == 32)
        #expect(Set(BeloteDeck.cards).count == 32)
    }
}
