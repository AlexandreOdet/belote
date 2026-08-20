//
//  StandardBeloteRoundScoringServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct StandardBeloteRoundScoringServiceTests {

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
}
