//
//  BeloteRoundPlaySessionPersistenceServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Testing
@testable import Belote

struct BeloteRoundPlaySessionPersistenceServiceTests {

    @MainActor
    @Test func persistenceServiceSavesAndLoadsRoundPlaySession() throws {
        let service = StandardBeloteRoundPlaySessionPersistenceService()
        let match = BeloteMatch()
        let session = StandardBeloteRoundPlayService().startSession(from: sampleCompletedDeal())

        try service.save(session, in: match)
        let restoredSession = try service.load(from: match)

        #expect(restoredSession == session)
    }

    @MainActor
    @Test func persistenceServiceClearsRoundPlaySession() throws {
        let service = StandardBeloteRoundPlaySessionPersistenceService()
        let match = BeloteMatch()
        let session = StandardBeloteRoundPlayService().startSession(from: sampleCompletedDeal())

        try service.save(session, in: match)
        service.clear(in: match)

        #expect(try service.load(from: match) == nil)
    }
}
