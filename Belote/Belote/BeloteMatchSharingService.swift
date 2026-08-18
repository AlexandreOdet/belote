//
//  BeloteMatchSharingService.swift
//  Belote
//
//  Created by Alexandre Odet on 05/08/2026.
//

import Foundation

protocol BeloteMatchSharingService {
    @MainActor
    func snapshot(for match: BeloteMatch) -> BeloteMatchSnapshot
    @MainActor
    func makeMatch(from snapshot: BeloteMatchSnapshot) throws -> BeloteMatch
    func encode(_ snapshot: BeloteMatchSnapshot) throws -> Data
    func decodeSnapshot(from data: Data) throws -> BeloteMatchSnapshot
    func makeInviteCode(for matchID: UUID) -> String
}

struct StandardBeloteMatchSharingService: BeloteMatchSharingService {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.sortedKeys]

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    @MainActor
    func snapshot(for match: BeloteMatch) -> BeloteMatchSnapshot {
        BeloteMatchSnapshot(match: match)
    }

    @MainActor
    func makeMatch(from snapshot: BeloteMatchSnapshot) throws -> BeloteMatch {
        guard snapshot.schemaVersion == 1 else {
            throw BeloteMatchSharingError.unsupportedSchemaVersion(snapshot.schemaVersion)
        }

        let match = BeloteMatch(
            matchID: snapshot.matchID,
            createdAt: snapshot.createdAt,
            teamAName: snapshot.teamAName,
            teamBName: snapshot.teamBName,
            teamAPlayerOneName: snapshot.teamAPlayerOneName,
            teamAPlayerTwoName: snapshot.teamAPlayerTwoName,
            teamBPlayerOneName: snapshot.teamBPlayerOneName,
            teamBPlayerTwoName: snapshot.teamBPlayerTwoName,
            firstDealerSeat: BelotePlayerSeat(rawValue: snapshot.firstDealerSeatRaw) ?? .teamAPlayerOne,
            targetScore: snapshot.targetScore
        )
        match.inviteCode = snapshot.inviteCode
        match.rounds = snapshot.rounds.map { roundSnapshot in
            BeloteRound(
                roundID: roundSnapshot.id,
                createdAt: roundSnapshot.createdAt,
                trickPointsTeamA: roundSnapshot.trickPointsTeamA,
                trickPointsTeamB: roundSnapshot.trickPointsTeamB,
                teamAPoints: roundSnapshot.teamAPoints,
                teamBPoints: roundSnapshot.teamBPoints,
                beloteTeam: roundSnapshot.beloteTeam,
                tookAllTricksTeam: roundSnapshot.tookAllTricksTeam,
                dealerSeat: roundSnapshot.dealerSeat,
                takerTeam: roundSnapshot.takerTeam,
                trumpSuit: roundSnapshot.trumpSuit,
                outcome: roundSnapshot.outcome,
                note: roundSnapshot.note,
                match: match
            )
        }

        return match
    }

    func encode(_ snapshot: BeloteMatchSnapshot) throws -> Data {
        try encoder.encode(snapshot)
    }

    func decodeSnapshot(from data: Data) throws -> BeloteMatchSnapshot {
        try decoder.decode(BeloteMatchSnapshot.self, from: data)
    }

    func makeInviteCode(for matchID: UUID) -> String {
        let compact = matchID.uuidString.replacingOccurrences(of: "-", with: "")
        let prefix = String(compact.prefix(8)).uppercased()
        return String(prefix.enumerated().flatMap { index, character -> [Character] in
            if index == 4 {
                return ["-", character]
            }

            return [character]
        })
    }
}

enum BeloteMatchSharingError: Error, Equatable, LocalizedError {
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return "Version de partage non supportee: \(version)."
        }
    }
}
