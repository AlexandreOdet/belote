//
//  BeloteRoundPlaySessionPersistenceService.swift
//  Belote
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Foundation

protocol BeloteRoundPlaySessionPersistenceService {
    func save(_ session: BeloteRoundPlaySession, in match: BeloteMatch) throws
    func load(from match: BeloteMatch) throws -> BeloteRoundPlaySession?
    func clear(in match: BeloteMatch)
}

enum BeloteRoundPlaySessionPersistenceError: Error, LocalizedError {
    case invalidSessionData

    var errorDescription: String? {
        switch self {
        case .invalidSessionData:
            return "La manche en cours ne peut pas etre restauree."
        }
    }
}

struct StandardBeloteRoundPlaySessionPersistenceService: BeloteRoundPlaySessionPersistenceService {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save(_ session: BeloteRoundPlaySession, in match: BeloteMatch) throws {
        match.activeRoundPlaySessionData = try encoder.encode(session)
    }

    func load(from match: BeloteMatch) throws -> BeloteRoundPlaySession? {
        guard let data = match.activeRoundPlaySessionData else {
            return nil
        }

        do {
            return try decoder.decode(BeloteRoundPlaySession.self, from: data)
        } catch {
            throw BeloteRoundPlaySessionPersistenceError.invalidSessionData
        }
    }

    func clear(in match: BeloteMatch) {
        match.activeRoundPlaySessionData = nil
    }
}
