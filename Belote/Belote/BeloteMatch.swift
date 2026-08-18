//
//  BeloteMatch.swift
//  Belote
//
//  Created by Alexandre Odet on 30/07/2026.
//

import Foundation
import SwiftData

@Model
final class BeloteMatch {
    var matchIDRaw: String
    var inviteCode: String
    var createdAt: Date
    var teamAName: String
    var teamBName: String
    var teamAPlayerOneName: String
    var teamAPlayerTwoName: String
    var teamBPlayerOneName: String
    var teamBPlayerTwoName: String
    var firstDealerSeatRaw: Int
    var targetScore: Int
    @Relationship(deleteRule: .cascade, inverse: \BeloteRound.match) var rounds: [BeloteRound]

    init(
        matchID: UUID = UUID(),
        createdAt: Date = Date(),
        teamAName: String = "Nous",
        teamBName: String = "Eux",
        teamAPlayerOneName: String = "Joueur 1",
        teamAPlayerTwoName: String = "Joueur 3",
        teamBPlayerOneName: String = "Joueur 2",
        teamBPlayerTwoName: String = "Joueur 4",
        firstDealerSeat: BelotePlayerSeat = .teamAPlayerOne,
        targetScore: Int = 1_000,
        rounds: [BeloteRound] = []
    ) {
        self.matchIDRaw = matchID.uuidString
        self.inviteCode = StandardBeloteMatchSharingService().makeInviteCode(for: matchID)
        self.createdAt = createdAt
        self.teamAName = teamAName
        self.teamBName = teamBName
        self.teamAPlayerOneName = teamAPlayerOneName
        self.teamAPlayerTwoName = teamAPlayerTwoName
        self.teamBPlayerOneName = teamBPlayerOneName
        self.teamBPlayerTwoName = teamBPlayerTwoName
        self.firstDealerSeatRaw = firstDealerSeat.rawValue
        self.targetScore = targetScore
        self.rounds = rounds
    }

    var sortedRounds: [BeloteRound] {
        rounds.sorted { $0.createdAt < $1.createdAt }
    }

    var matchID: UUID {
        UUID(uuidString: matchIDRaw) ?? UUID()
    }

    var teamAScore: Int {
        rounds.reduce(0) { $0 + $1.teamAPoints }
    }

    var teamBScore: Int {
        rounds.reduce(0) { $0 + $1.teamBPoints }
    }

    var winningTeam: BeloteTeam? {
        BeloteScoring.winningTeam(teamAScore: teamAScore, teamBScore: teamBScore, targetScore: targetScore)
    }

    var firstDealerSeat: BelotePlayerSeat {
        BelotePlayerSeat(rawValue: firstDealerSeatRaw) ?? .teamAPlayerOne
    }

    var nextDealerSeat: BelotePlayerSeat {
        var seat = firstDealerSeat

        for _ in sortedRounds {
            seat = seat.next
        }

        return seat
    }

    func displayName(for team: BeloteTeam) -> String {
        switch team {
        case .teamA:
            return teamAName
        case .teamB:
            return teamBName
        }
    }

    func displayName(for seat: BelotePlayerSeat) -> String {
        switch seat {
        case .teamAPlayerOne:
            return teamAPlayerOneName
        case .teamAPlayerTwo:
            return teamAPlayerTwoName
        case .teamBPlayerOne:
            return teamBPlayerOneName
        case .teamBPlayerTwo:
            return teamBPlayerTwoName
        }
    }
}
