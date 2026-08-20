//
//  BeloteJoinLinkServiceTests.swift
//  BeloteTests
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Foundation
import Testing
@testable import Belote

struct BeloteJoinLinkServiceTests {

    @Test func joinLinkServiceBuildsJoinURLFromInviteCode() throws {
        let service = StandardBeloteJoinLinkService()

        let url = try service.makeJoinURL(inviteCode: "1234-5678")

        #expect(url.absoluteString == "belote://join?code=1234-5678")
    }

    @Test func joinLinkServiceNormalizesInviteCode() throws {
        let service = StandardBeloteJoinLinkService()

        let url = try service.makeJoinURL(inviteCode: " abcd-1234 ")

        #expect(url.absoluteString == "belote://join?code=ABCD-1234")
    }

    @Test func joinLinkServiceExtractsInviteCodeFromJoinURL() throws {
        let service = StandardBeloteJoinLinkService()
        let url = URL(string: "belote://join?code=abcd-1234")!

        let inviteCode = service.inviteCode(from: url)

        #expect(inviteCode == "ABCD-1234")
    }

    @Test func joinLinkServiceRejectsEmptyInviteCode() {
        let service = StandardBeloteJoinLinkService()

        #expect(throws: BeloteJoinLinkError.invalidInviteCode) {
            try service.makeJoinURL(inviteCode: " ")
        }
    }

    @Test func joinLinkServiceIgnoresUnsupportedURL() {
        let service = StandardBeloteJoinLinkService()
        let url = URL(string: "https://example.com/join?code=1234-5678")!

        #expect(service.inviteCode(from: url) == nil)
    }
}
