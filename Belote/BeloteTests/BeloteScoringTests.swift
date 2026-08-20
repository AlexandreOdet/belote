//
//  BeloteScoringTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct BeloteScoringTests {

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
}
