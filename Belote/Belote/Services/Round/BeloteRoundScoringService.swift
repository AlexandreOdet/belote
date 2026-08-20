//
//  BeloteRoundScoringService.swift
//  Belote
//
//  Created by Alexandre Odet on 05/08/2026.
//

import Foundation

struct BeloteRoundScoreInput: Equatable {
    let takerTeam: BeloteTeam
    let trickPointsTeamA: Int
    let trickPointsTeamB: Int
    let beloteTeam: BeloteTeam?
    let tookAllTricksTeam: BeloteTeam?
}

struct BeloteRoundScoreResult: Equatable {
    let teamAPoints: Int
    let teamBPoints: Int
    let outcome: BeloteRoundOutcome
    let takerTrickPoints: Int
    let defenderTrickPoints: Int

    var didTakerSucceed: Bool {
        switch outcome {
        case .contractMade, .capotMade:
            return true
        case .contractFailed, .litigation:
            return false
        }
    }
}

enum BeloteRoundOutcome: String, CaseIterable, Identifiable {
    case contractMade
    case contractFailed
    case capotMade
    case litigation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .contractMade:
            return "Contrat fait"
        case .contractFailed:
            return "Dedans"
        case .capotMade:
            return "Capot"
        case .litigation:
            return "Litige"
        }
    }
}

struct BeloteRoundScoringRules: Equatable {
    var baseRoundPoints = 162
    var capotPoints = 252
    var beloteBonus = 20
    var beloteIsAlwaysScored = true
    var beloteCountsForContract = true
}

protocol BeloteRoundScoringService {
    var rules: BeloteRoundScoringRules { get }

    func scoreRound(_ input: BeloteRoundScoreInput) throws -> BeloteRoundScoreResult
}

enum BeloteRoundScoringError: Error, Equatable, LocalizedError {
    case negativeTrickPoints
    case invalidTrickPointTotal(expected: Int, actual: Int)
    case capotWinnerHasTrickPointsMismatch

    var errorDescription: String? {
        switch self {
        case .negativeTrickPoints:
            return "Les points de plis ne peuvent pas etre negatifs."
        case let .invalidTrickPointTotal(expected, actual):
            return "Le total des plis doit faire \(expected) points, pas \(actual)."
        case .capotWinnerHasTrickPointsMismatch:
            return "Une equipe capot doit avoir tous les points de plis."
        }
    }
}
