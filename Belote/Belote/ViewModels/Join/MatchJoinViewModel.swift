//
//  MatchJoinViewModel.swift
//  Belote
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Foundation

struct MatchJoinViewModel {
    var inviteCode = ""
    var statusMessage: String?
    var isImporting = false

    mutating func apply(url: URL, joinLinkService: any BeloteJoinLinkService) -> Bool {
        guard let inviteCode = joinLinkService.inviteCode(from: url) else {
            statusMessage = "Ce QR Code ne correspond pas a une partie Belote."
            return false
        }

        self.inviteCode = inviteCode
        statusMessage = nil
        return true
    }

    @MainActor
    mutating func importMatch(
        matchSyncService: any BeloteMatchSyncService,
        sharingService: any BeloteMatchSharingService
    ) async -> BeloteMatch? {
        let normalizedInviteCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalizedInviteCode.isEmpty else {
            statusMessage = "Entre un code ou scanne un QR Code."
            return nil
        }

        isImporting = true
        statusMessage = "Import CloudKit en cours..."

        do {
            let match = try await matchSyncService.download(
                inviteCode: normalizedInviteCode,
                sharingService: sharingService
            )
            inviteCode = normalizedInviteCode
            statusMessage = "Partie importee depuis CloudKit."
            isImporting = false
            return match
        } catch {
            statusMessage = error.localizedDescription
            isImporting = false
            return nil
        }
    }
}
