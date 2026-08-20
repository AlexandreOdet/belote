//
//  BeloteShareModels.swift
//  Belote
//
//  Created by Alexandre Odet on 05/08/2026.
//

import Foundation

struct BeloteMatchSnapshot: Codable, Equatable {
    let schemaVersion: Int
    let matchID: UUID
    let inviteCode: String
    let updatedAt: Date
    let createdAt: Date
    let teamAName: String
    let teamBName: String
    let teamAPlayerOneName: String
    let teamAPlayerTwoName: String
    let teamBPlayerOneName: String
    let teamBPlayerTwoName: String
    let firstDealerSeatRaw: Int
    let targetScore: Int
    let rounds: [BeloteRoundSnapshot]

    @MainActor
    init(match: BeloteMatch, updatedAt: Date = Date()) {
        self.schemaVersion = 1
        self.matchID = match.matchID
        self.inviteCode = match.inviteCode
        self.updatedAt = updatedAt
        self.createdAt = match.createdAt
        self.teamAName = match.teamAName
        self.teamBName = match.teamBName
        self.teamAPlayerOneName = match.teamAPlayerOneName
        self.teamAPlayerTwoName = match.teamAPlayerTwoName
        self.teamBPlayerOneName = match.teamBPlayerOneName
        self.teamBPlayerTwoName = match.teamBPlayerTwoName
        self.firstDealerSeatRaw = match.firstDealerSeatRaw
        self.targetScore = match.targetScore
        self.rounds = match.sortedRounds.map(BeloteRoundSnapshot.init(round:))
    }
}

struct BeloteRoundSnapshot: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let trickPointsTeamA: Int
    let trickPointsTeamB: Int
    let teamAPoints: Int
    let teamBPoints: Int
    let beloteTeamRaw: Int?
    let tookAllTricksTeamRaw: Int?
    let dealerSeatRaw: Int
    let takerTeamRaw: Int
    let trumpSuitRaw: String
    let outcomeRaw: String
    let note: String

    @MainActor
    init(round: BeloteRound) {
        self.id = round.roundID
        self.createdAt = round.createdAt
        self.trickPointsTeamA = round.trickPointsTeamA
        self.trickPointsTeamB = round.trickPointsTeamB
        self.teamAPoints = round.teamAPoints
        self.teamBPoints = round.teamBPoints
        self.beloteTeamRaw = round.beloteTeamRaw
        self.tookAllTricksTeamRaw = round.tookAllTricksTeamRaw
        self.dealerSeatRaw = round.dealerSeatRaw
        self.takerTeamRaw = round.takerTeamRaw
        self.trumpSuitRaw = round.trumpSuitRaw
        self.outcomeRaw = round.outcomeRaw
        self.note = round.note
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

    var dealerSeat: BelotePlayerSeat {
        BelotePlayerSeat(rawValue: dealerSeatRaw) ?? .teamAPlayerOne
    }

    var takerTeam: BeloteTeam {
        BeloteTeam(rawValue: takerTeamRaw) ?? .teamA
    }

    var trumpSuit: BeloteSuit {
        BeloteSuit(rawValue: trumpSuitRaw) ?? .hearts
    }

    var outcome: BeloteRoundOutcome {
        BeloteRoundOutcome(rawValue: outcomeRaw) ?? .contractMade
    }
}

enum BeloteMatchEvent: Codable, Equatable, Identifiable {
    case matchCreated(BeloteMatchSnapshot)
    case roundAdded(matchID: UUID, round: BeloteRoundSnapshot)
    case roundRemoved(matchID: UUID, roundID: UUID)

    var id: String {
        switch self {
        case let .matchCreated(snapshot):
            return "matchCreated-\(snapshot.matchID.uuidString)"
        case let .roundAdded(matchID, round):
            return "roundAdded-\(matchID.uuidString)-\(round.id.uuidString)"
        case let .roundRemoved(matchID, roundID):
            return "roundRemoved-\(matchID.uuidString)-\(roundID.uuidString)"
        }
    }
}
