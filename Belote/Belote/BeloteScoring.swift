//
//  BeloteScoring.swift
//  Belote
//
//  Created by Alexandre Odet on 30/07/2026.
//

import Foundation

enum BeloteScoring {
    static let baseRoundPoints = 162
    static let beloteBonus = 20

    static func roundTotal(hasBelote: Bool) -> Int {
        baseRoundPoints + (hasBelote ? beloteBonus : 0)
    }

    static func isRoundTotalValid(teamAPoints: Int, teamBPoints: Int, hasBelote: Bool) -> Bool {
        teamAPoints >= 0 && teamBPoints >= 0 && teamAPoints + teamBPoints == roundTotal(hasBelote: hasBelote)
    }

    static func winningTeam(teamAScore: Int, teamBScore: Int, targetScore: Int) -> BeloteTeam? {
        guard teamAScore >= targetScore || teamBScore >= targetScore else {
            return nil
        }

        if teamAScore == teamBScore {
            return nil
        }

        return teamAScore > teamBScore ? .teamA : .teamB
    }
}
