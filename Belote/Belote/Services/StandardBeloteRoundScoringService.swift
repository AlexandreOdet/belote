//
//  StandardBeloteRoundScoringService.swift
//  Belote
//
//  Created by Alexandre Odet on 05/08/2026.
//

import Foundation

struct StandardBeloteRoundScoringService: BeloteRoundScoringService {
    let rules: BeloteRoundScoringRules

    init(rules: BeloteRoundScoringRules = BeloteRoundScoringRules()) {
        self.rules = rules
    }

    func scoreRound(_ input: BeloteRoundScoreInput) throws -> BeloteRoundScoreResult {
        try validate(input)

        let takerTrickPoints = input.trickPoints(for: input.takerTeam)
        let defenderTeam = input.takerTeam.opponent
        let defenderTrickPoints = input.trickPoints(for: defenderTeam)
        let takerContractPoints = takerTrickPoints + contractBeloteBonus(for: input.takerTeam, in: input)
        let defenderContractPoints = defenderTrickPoints + contractBeloteBonus(for: defenderTeam, in: input)

        if let capotTeam = input.tookAllTricksTeam {
            return capotResult(winningTeam: capotTeam, input: input, takerTrickPoints: takerTrickPoints, defenderTrickPoints: defenderTrickPoints)
        }

        if takerContractPoints == defenderContractPoints {
            return litigationResult(input: input, takerTrickPoints: takerTrickPoints, defenderTrickPoints: defenderTrickPoints)
        }

        if takerContractPoints > defenderContractPoints {
            return standardResult(input: input, outcome: .contractMade, takerTrickPoints: takerTrickPoints, defenderTrickPoints: defenderTrickPoints)
        }

        return failedContractResult(input: input, takerTrickPoints: takerTrickPoints, defenderTrickPoints: defenderTrickPoints)
    }

    private func validate(_ input: BeloteRoundScoreInput) throws {
        guard input.trickPointsTeamA >= 0 && input.trickPointsTeamB >= 0 else {
            throw BeloteRoundScoringError.negativeTrickPoints
        }

        let total = input.trickPointsTeamA + input.trickPointsTeamB
        guard total == rules.baseRoundPoints else {
            throw BeloteRoundScoringError.invalidTrickPointTotal(expected: rules.baseRoundPoints, actual: total)
        }

        guard let capotTeam = input.tookAllTricksTeam else {
            return
        }

        guard input.trickPoints(for: capotTeam) == rules.baseRoundPoints && input.trickPoints(for: capotTeam.opponent) == 0 else {
            throw BeloteRoundScoringError.capotWinnerHasTrickPointsMismatch
        }
    }

    private func standardResult(input: BeloteRoundScoreInput, outcome: BeloteRoundOutcome, takerTrickPoints: Int, defenderTrickPoints: Int) -> BeloteRoundScoreResult {
        BeloteRoundScoreResult(
            teamAPoints: input.trickPointsTeamA + scoredBeloteBonus(for: .teamA, in: input),
            teamBPoints: input.trickPointsTeamB + scoredBeloteBonus(for: .teamB, in: input),
            outcome: outcome,
            takerTrickPoints: takerTrickPoints,
            defenderTrickPoints: defenderTrickPoints
        )
    }

    private func failedContractResult(input: BeloteRoundScoreInput, takerTrickPoints: Int, defenderTrickPoints: Int) -> BeloteRoundScoreResult {
        let takerBonus = scoredBeloteBonus(for: input.takerTeam, in: input)
        let defenderTeam = input.takerTeam.opponent
        let defenderBonus = scoredBeloteBonus(for: defenderTeam, in: input)
        let takerPoints = rules.beloteIsAlwaysScored ? takerBonus : 0
        let defenderPoints = rules.baseRoundPoints + defenderBonus + (rules.beloteIsAlwaysScored ? 0 : takerBonus)

        return BeloteRoundScoreResult(
            teamAPoints: input.takerTeam == .teamA ? takerPoints : defenderPoints,
            teamBPoints: input.takerTeam == .teamB ? takerPoints : defenderPoints,
            outcome: .contractFailed,
            takerTrickPoints: takerTrickPoints,
            defenderTrickPoints: defenderTrickPoints
        )
    }

    private func capotResult(winningTeam: BeloteTeam, input: BeloteRoundScoreInput, takerTrickPoints: Int, defenderTrickPoints: Int) -> BeloteRoundScoreResult {
        let losingTeam = winningTeam.opponent
        let winningPoints = rules.capotPoints + scoredBeloteBonus(for: winningTeam, in: input)
        let losingPoints = rules.beloteIsAlwaysScored ? scoredBeloteBonus(for: losingTeam, in: input) : 0

        return BeloteRoundScoreResult(
            teamAPoints: winningTeam == .teamA ? winningPoints : losingPoints,
            teamBPoints: winningTeam == .teamB ? winningPoints : losingPoints,
            outcome: .capotMade,
            takerTrickPoints: takerTrickPoints,
            defenderTrickPoints: defenderTrickPoints
        )
    }

    private func litigationResult(input: BeloteRoundScoreInput, takerTrickPoints: Int, defenderTrickPoints: Int) -> BeloteRoundScoreResult {
        let defenderTeam = input.takerTeam.opponent
        let takerBonus = scoredBeloteBonus(for: input.takerTeam, in: input)
        let defenderPoints = defenderTrickPoints + scoredBeloteBonus(for: defenderTeam, in: input)
        let takerPoints = rules.beloteIsAlwaysScored ? takerBonus : 0

        return BeloteRoundScoreResult(
            teamAPoints: input.takerTeam == .teamA ? takerPoints : defenderPoints,
            teamBPoints: input.takerTeam == .teamB ? takerPoints : defenderPoints,
            outcome: .litigation,
            takerTrickPoints: takerTrickPoints,
            defenderTrickPoints: defenderTrickPoints
        )
    }

    private func contractBeloteBonus(for team: BeloteTeam, in input: BeloteRoundScoreInput) -> Int {
        guard rules.beloteCountsForContract else {
            return 0
        }

        return scoredBeloteBonus(for: team, in: input)
    }

    private func scoredBeloteBonus(for team: BeloteTeam, in input: BeloteRoundScoreInput) -> Int {
        input.beloteTeam == team ? rules.beloteBonus : 0
    }
}

private extension BeloteRoundScoreInput {
    func trickPoints(for team: BeloteTeam) -> Int {
        switch team {
        case .teamA:
            return trickPointsTeamA
        case .teamB:
            return trickPointsTeamB
        }
    }
}
