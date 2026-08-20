//
//  BeloteMatchTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct BeloteMatchTests {

    @Test func dealerRotatesAfterEachRound() {
        let match = BeloteMatch(firstDealerSeat: .teamBPlayerOne)

        #expect(match.nextDealerSeat == .teamBPlayerOne)

        match.rounds.append(BeloteRound(teamAPoints: 82, teamBPoints: 80, dealerSeat: match.nextDealerSeat))
        #expect(match.nextDealerSeat == .teamAPlayerTwo)

        match.rounds.append(BeloteRound(teamAPoints: 90, teamBPoints: 72, dealerSeat: match.nextDealerSeat))
        #expect(match.nextDealerSeat == .teamBPlayerTwo)
    }
}
