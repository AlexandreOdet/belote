//
//  MatchJoinViewModelTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Foundation
import Testing
@testable import Belote

struct MatchJoinViewModelTests {

    @MainActor
    @Test func matchJoinViewModelAppliesJoinURL() {
        let linkService = StandardBeloteJoinLinkService()
        let url = URL(string: "belote://join?code=abcd-1234")!
        var viewModel = MatchJoinViewModel()

        let didApply = viewModel.apply(url: url, joinLinkService: linkService)

        #expect(didApply)
        #expect(viewModel.inviteCode == "ABCD-1234")
        #expect(viewModel.statusMessage == nil)
    }

    @MainActor
    @Test func matchJoinViewModelRejectsUnsupportedURL() {
        let linkService = StandardBeloteJoinLinkService()
        let url = URL(string: "https://example.com/join?code=abcd-1234")!
        var viewModel = MatchJoinViewModel()

        let didApply = viewModel.apply(url: url, joinLinkService: linkService)

        #expect(!didApply)
        #expect(viewModel.inviteCode.isEmpty)
        #expect(viewModel.statusMessage == "Ce QR Code ne correspond pas a une partie Belote.")
    }

    @MainActor
    @Test func matchJoinViewModelImportsMatchFromCloudKit() async throws {
        let match = BeloteMatch(teamAName: "Nord Sud", teamBName: "Est Ouest")
        let syncService = FakeBeloteMatchSyncService(match: match)
        let sharingService = StandardBeloteMatchSharingService()
        var viewModel = MatchJoinViewModel(inviteCode: " abcd-1234 ")

        let importedMatch = await viewModel.importMatch(
            matchSyncService: syncService,
            sharingService: sharingService
        )

        #expect(importedMatch === match)
        #expect(syncService.downloadedInviteCode == "ABCD-1234")
        #expect(viewModel.inviteCode == "ABCD-1234")
        #expect(viewModel.statusMessage == "Partie importee depuis CloudKit.")
        #expect(!viewModel.isImporting)
    }

    @MainActor
    @Test func matchJoinViewModelRequiresInviteCodeBeforeImport() async {
        let syncService = FakeBeloteMatchSyncService(match: BeloteMatch())
        let sharingService = StandardBeloteMatchSharingService()
        var viewModel = MatchJoinViewModel(inviteCode: " ")

        let importedMatch = await viewModel.importMatch(
            matchSyncService: syncService,
            sharingService: sharingService
        )

        #expect(importedMatch == nil)
        #expect(viewModel.statusMessage == "Entre un code ou scanne un QR Code.")
    }
}

@MainActor
private final class FakeBeloteMatchSyncService: BeloteMatchSyncService {
    let match: BeloteMatch
    var downloadedInviteCode: String?

    init(match: BeloteMatch) {
        self.match = match
    }

    func upload(match: BeloteMatch, sharingService: any BeloteMatchSharingService) async throws -> BeloteCloudMatchReference {
        BeloteCloudMatchReference(inviteCode: match.inviteCode, updatedAt: Date())
    }

    func download(inviteCode: String, sharingService: any BeloteMatchSharingService) async throws -> BeloteMatch {
        downloadedInviteCode = inviteCode
        return match
    }
}
