//
//  BeloteTeam.swift
//  Belote
//
//  Created by Alexandre Odet on 30/07/2026.
//

import Foundation

enum BeloteTeam: Int, CaseIterable, Identifiable {
    case teamA
    case teamB

    var id: Int { rawValue }

    var opponent: BeloteTeam {
        switch self {
        case .teamA:
            return .teamB
        case .teamB:
            return .teamA
        }
    }
}

enum BelotePlayerSeat: Int, CaseIterable, Identifiable {
    case teamAPlayerOne
    case teamBPlayerOne
    case teamAPlayerTwo
    case teamBPlayerTwo

    var id: Int { rawValue }

    var team: BeloteTeam {
        switch self {
        case .teamAPlayerOne, .teamAPlayerTwo:
            return .teamA
        case .teamBPlayerOne, .teamBPlayerTwo:
            return .teamB
        }
    }

    var next: BelotePlayerSeat {
        BelotePlayerSeat(rawValue: (rawValue + 1) % BelotePlayerSeat.allCases.count) ?? .teamAPlayerOne
    }
}
