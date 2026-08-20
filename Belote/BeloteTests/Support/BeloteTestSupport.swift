//
//  BeloteTestSupport.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Foundation
@testable import Belote

struct PredictableRandomNumberGenerator: RandomNumberGenerator {
    var value: UInt64 = 0

    mutating func next() -> UInt64 {
        defer { value += 1 }
        return value
    }
}

func sampleCompletedDeal() -> BeloteCompletedDeal {
    var randomGenerator = PredictableRandomNumberGenerator()
    let dealService = StandardBeloteDealService()
    let initialDeal = dealService.startDeal(dealerSeat: .teamAPlayerOne, randomGenerator: &randomGenerator)
    return try! dealService.completeDeal(initialDeal, selection: .firstRound(takerSeat: .teamBPlayerOne))
}

func card(_ suit: BeloteCardSuit, _ rank: BeloteCardRank) -> BeloteCard {
    BeloteCard(suit: suit, rank: rank)
}
