//
//  BeloteMatchSharingServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Foundation
import Testing
@testable import Belote

struct BeloteMatchSharingServiceTests {

    @Test func sharingServiceCreatesStableInviteCodeFromMatchID() {
        let service = StandardBeloteMatchSharingService()
        let matchID = UUID(uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF")!

        #expect(service.makeInviteCode(for: matchID) == "1234-5678")
    }

    @MainActor
    @Test func sharingServiceRoundTripsMatchSnapshotAsJSON() throws {
        let service = StandardBeloteMatchSharingService()
        let matchID = UUID(uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF")!
        let roundID = UUID(uuidString: "ABCDEF12-3456-7890-ABCD-EF1234567890")!
        let match = BeloteMatch(
            matchID: matchID,
            createdAt: Date(timeIntervalSince1970: 1_800),
            teamAName: "Nord Sud",
            teamBName: "Est Ouest",
            firstDealerSeat: .teamBPlayerOne
        )
        match.rounds.append(
            BeloteRound(
                roundID: roundID,
                createdAt: Date(timeIntervalSince1970: 2_400),
                trickPointsTeamA: 90,
                trickPointsTeamB: 72,
                teamAPoints: 90,
                teamBPoints: 72,
                dealerSeat: .teamBPlayerOne,
                takerTeam: .teamA,
                trumpSuit: .hearts,
                outcome: .contractMade
            )
        )

        let snapshot = service.snapshot(for: match)
        let data = try service.encode(snapshot)
        let decoded = try service.decodeSnapshot(from: data)

        #expect(decoded == snapshot)
        #expect(decoded.matchID == matchID)
        #expect(decoded.inviteCode == "1234-5678")
        #expect(decoded.rounds.first?.id == roundID)
    }

    @MainActor
    @Test func sharingServiceBuildsLocalMatchFromSnapshot() throws {
        let service = StandardBeloteMatchSharingService()
        let matchID = UUID(uuidString: "87654321-90AB-CDEF-1234-567890ABCDEF")!
        let source = BeloteMatch(
            matchID: matchID,
            teamAName: "Alice Bob",
            teamBName: "Chloe Dan",
            targetScore: 1_500
        )
        source.rounds.append(
            BeloteRound(
                trickPointsTeamA: 80,
                trickPointsTeamB: 82,
                teamAPoints: 0,
                teamBPoints: 162,
                dealerSeat: .teamAPlayerOne,
                takerTeam: .teamA,
                trumpSuit: .spades,
                outcome: .contractFailed,
                note: "Dedans"
            )
        )

        let imported = try service.makeMatch(from: service.snapshot(for: source))

        #expect(imported.matchID == matchID)
        #expect(imported.inviteCode == source.inviteCode)
        #expect(imported.teamAName == "Alice Bob")
        #expect(imported.targetScore == 1_500)
        #expect(imported.teamAScore == 0)
        #expect(imported.teamBScore == 162)
        #expect(imported.sortedRounds.first?.outcome == .contractFailed)
        #expect(imported.sortedRounds.first?.note == "Dedans")
    }
}
