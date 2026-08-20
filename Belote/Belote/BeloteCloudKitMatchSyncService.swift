//
//  BeloteCloudKitMatchSyncService.swift
//  Belote
//
//  Created by Alexandre Odet on 20/08/2026.
//

import CloudKit
import Foundation

struct BeloteCloudMatchReference: Equatable {
    let inviteCode: String
    let updatedAt: Date
}

protocol BeloteMatchSyncService {
    @MainActor
    func upload(match: BeloteMatch, sharingService: any BeloteMatchSharingService) async throws -> BeloteCloudMatchReference

    @MainActor
    func download(inviteCode: String, sharingService: any BeloteMatchSharingService) async throws -> BeloteMatch
}

protocol BeloteCloudRecordDatabase {
    func save(_ record: CKRecord) async throws -> CKRecord
    func record(for recordID: CKRecord.ID) async throws -> CKRecord
}

extension CKDatabase: BeloteCloudRecordDatabase {}

enum BeloteCloudKitMatchSyncError: Error, Equatable, LocalizedError {
    case missingPayload
    case invalidInviteCode

    var errorDescription: String? {
        switch self {
        case .missingPayload:
            return "La partie CloudKit ne contient pas de donnees exploitables."
        case .invalidInviteCode:
            return "Le code de partage CloudKit est vide."
        }
    }
}

struct CloudKitBeloteMatchSyncService: BeloteMatchSyncService {
    private let database: any BeloteCloudRecordDatabase

    init(database: any BeloteCloudRecordDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }

    @MainActor
    func upload(match: BeloteMatch, sharingService: any BeloteMatchSharingService) async throws -> BeloteCloudMatchReference {
        let snapshot = sharingService.snapshot(for: match)
        let payload = try sharingService.encode(snapshot)
        let record = CKRecord(recordType: BeloteCloudKitMatchRecord.recordType, recordID: recordID(for: snapshot.inviteCode))

        BeloteCloudKitMatchRecord.fill(record, with: snapshot, payload: payload)
        let savedRecord = try await database.save(record)
        return try BeloteCloudKitMatchRecord.reference(from: savedRecord)
    }

    @MainActor
    func download(inviteCode: String, sharingService: any BeloteMatchSharingService) async throws -> BeloteMatch {
        let normalizedInviteCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalizedInviteCode.isEmpty else {
            throw BeloteCloudKitMatchSyncError.invalidInviteCode
        }

        let record = try await database.record(for: recordID(for: normalizedInviteCode))
        let payload = try BeloteCloudKitMatchRecord.payload(from: record)
        let snapshot = try sharingService.decodeSnapshot(from: payload)
        return try sharingService.makeMatch(from: snapshot)
    }

    private func recordID(for inviteCode: String) -> CKRecord.ID {
        CKRecord.ID(recordName: inviteCode)
    }
}

enum BeloteCloudKitMatchRecord {
    static let recordType = "BeloteMatchSnapshot"
    private static let inviteCodeKey = "inviteCode"
    private static let matchIDKey = "matchID"
    private static let updatedAtKey = "updatedAt"
    private static let payloadKey = "payload"

    static func fill(_ record: CKRecord, with snapshot: BeloteMatchSnapshot, payload: Data) {
        record[inviteCodeKey] = snapshot.inviteCode as CKRecordValue
        record[matchIDKey] = snapshot.matchID.uuidString as CKRecordValue
        record[updatedAtKey] = snapshot.updatedAt as CKRecordValue
        record[payloadKey] = payload as CKRecordValue
    }

    static func payload(from record: CKRecord) throws -> Data {
        guard let payload = record[payloadKey] as? Data else {
            throw BeloteCloudKitMatchSyncError.missingPayload
        }

        return payload
    }

    static func reference(from record: CKRecord) throws -> BeloteCloudMatchReference {
        guard let inviteCode = record[inviteCodeKey] as? String,
              let updatedAt = record[updatedAtKey] as? Date else {
            throw BeloteCloudKitMatchSyncError.missingPayload
        }

        return BeloteCloudMatchReference(inviteCode: inviteCode, updatedAt: updatedAt)
    }
}
