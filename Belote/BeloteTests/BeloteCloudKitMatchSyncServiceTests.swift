//
//  BeloteCloudKitMatchSyncServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import CloudKit
import Foundation
import Testing
@testable import Belote

struct BeloteCloudKitMatchSyncServiceTests {

    @MainActor
    @Test func cloudKitSyncServiceUploadsSnapshotRecord() async throws {
        let database = InMemoryCloudRecordDatabase()
        let sharingService = StandardBeloteMatchSharingService()
        let syncService = CloudKitBeloteMatchSyncService(database: database)
        let matchID = UUID(uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF")!
        let match = BeloteMatch(matchID: matchID)

        let reference = try await syncService.upload(match: match, sharingService: sharingService)
        let record = try await database.record(for: CKRecord.ID(recordName: "1234-5678"))

        #expect(reference.inviteCode == "1234-5678")
        #expect(record.recordType == "BeloteMatchSnapshot")
        #expect(record["inviteCode"] as? String == "1234-5678")
        #expect(record["matchID"] as? String == matchID.uuidString)
        #expect(record["payload"] as? Data != nil)
    }

    @MainActor
    @Test func cloudKitSyncServiceDownloadsMatchFromInviteCode() async throws {
        let database = InMemoryCloudRecordDatabase()
        let sharingService = StandardBeloteMatchSharingService()
        let syncService = CloudKitBeloteMatchSyncService(database: database)
        let source = BeloteMatch(teamAName: "Nord Sud", teamBName: "Est Ouest")

        _ = try await syncService.upload(match: source, sharingService: sharingService)
        let downloaded = try await syncService.download(inviteCode: source.inviteCode.lowercased(), sharingService: sharingService)

        #expect(downloaded.matchID == source.matchID)
        #expect(downloaded.teamAName == "Nord Sud")
        #expect(downloaded.teamBName == "Est Ouest")
        #expect(downloaded.inviteCode == source.inviteCode)
    }

    @MainActor
    @Test func cloudKitSyncServiceRejectsEmptyInviteCode() async throws {
        let database = InMemoryCloudRecordDatabase()
        let sharingService = StandardBeloteMatchSharingService()
        let syncService = CloudKitBeloteMatchSyncService(database: database)

        await #expect(throws: BeloteCloudKitMatchSyncError.invalidInviteCode) {
            try await syncService.download(inviteCode: " ", sharingService: sharingService)
        }
    }
}

private final class InMemoryCloudRecordDatabase: BeloteCloudRecordDatabase {
    private var records: [CKRecord.ID: CKRecord] = [:]

    func save(_ record: CKRecord) async throws -> CKRecord {
        records[record.recordID] = record
        return record
    }

    func record(for recordID: CKRecord.ID) async throws -> CKRecord {
        if let record = records[recordID] {
            return record
        }

        throw CKError(.unknownItem)
    }
}
