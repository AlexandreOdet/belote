//
//  BeloteRound.swift
//  Belote
//
//  Created by Alexandre Odet on 30/07/2026.
//

import Foundation
import SwiftData

@Model
final class BeloteRound {
    var roundIDRaw: String
    var createdAt: Date
    var trickPointsTeamA: Int
    var trickPointsTeamB: Int
    var teamAPoints: Int
    var teamBPoints: Int
    var beloteTeamRaw: Int?
    var tookAllTricksTeamRaw: Int?
    var dealerSeatRaw: Int
    var takerTeamRaw: Int
    var trumpSuitRaw: String
    var outcomeRaw: String
    var note: String
    var match: BeloteMatch?

    init(
        roundID: UUID = UUID(),
        createdAt: Date = Date(),
        trickPointsTeamA: Int,
        trickPointsTeamB: Int,
        teamAPoints: Int,
        teamBPoints: Int,
        beloteTeam: BeloteTeam? = nil,
        tookAllTricksTeam: BeloteTeam? = nil,
        dealerSeat: BelotePlayerSeat = .teamAPlayerOne,
        takerTeam: BeloteTeam = .teamA,
        trumpSuit: BeloteSuit = .hearts,
        outcome: BeloteRoundOutcome = .contractMade,
        note: String = "",
        match: BeloteMatch? = nil
    ) {
        self.roundIDRaw = roundID.uuidString
        self.createdAt = createdAt
        self.trickPointsTeamA = trickPointsTeamA
        self.trickPointsTeamB = trickPointsTeamB
        self.teamAPoints = teamAPoints
        self.teamBPoints = teamBPoints
        self.beloteTeamRaw = beloteTeam?.rawValue
        self.tookAllTricksTeamRaw = tookAllTricksTeam?.rawValue
        self.dealerSeatRaw = dealerSeat.rawValue
        self.takerTeamRaw = takerTeam.rawValue
        self.trumpSuitRaw = trumpSuit.rawValue
        self.outcomeRaw = outcome.rawValue
        self.note = note
        self.match = match
    }

    convenience init(
        roundID: UUID = UUID(),
        createdAt: Date = Date(),
        teamAPoints: Int,
        teamBPoints: Int,
        hasBelote: Bool = false,
        dealerSeat: BelotePlayerSeat = .teamAPlayerOne,
        takerTeam: BeloteTeam = .teamA,
        trumpSuit: BeloteSuit = .hearts,
        note: String = "",
        match: BeloteMatch? = nil
    ) {
        self.init(
            roundID: roundID,
            createdAt: createdAt,
            trickPointsTeamA: teamAPoints,
            trickPointsTeamB: teamBPoints,
            teamAPoints: teamAPoints,
            teamBPoints: teamBPoints + (hasBelote ? BeloteScoring.beloteBonus : 0),
            beloteTeam: hasBelote ? .teamB : nil,
            dealerSeat: dealerSeat,
            takerTeam: takerTeam,
            trumpSuit: trumpSuit,
            note: note,
            match: match
        )
    }

    var dealerSeat: BelotePlayerSeat {
        BelotePlayerSeat(rawValue: dealerSeatRaw) ?? .teamAPlayerOne
    }

    var roundID: UUID {
        UUID(uuidString: roundIDRaw) ?? UUID()
    }

    var takerTeam: BeloteTeam {
        BeloteTeam(rawValue: takerTeamRaw) ?? .teamA
    }

    var trumpSuit: BeloteSuit {
        BeloteSuit(rawValue: trumpSuitRaw) ?? .hearts
    }

    var beloteTeam: BeloteTeam? {
        guard let beloteTeamRaw else {
            return nil
        }

        return BeloteTeam(rawValue: beloteTeamRaw)
    }

    var tookAllTricksTeam: BeloteTeam? {
        guard let tookAllTricksTeamRaw else {
            return nil
        }

        return BeloteTeam(rawValue: tookAllTricksTeamRaw)
    }

    var outcome: BeloteRoundOutcome {
        BeloteRoundOutcome(rawValue: outcomeRaw) ?? .contractMade
    }

    var hasBelote: Bool {
        beloteTeam != nil
    }
}
