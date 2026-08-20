//
//  BeloteJoinLinkService.swift
//  Belote
//
//  Created by Alexandre Odet on 20/08/2026.
//

import Foundation

protocol BeloteJoinLinkService {
    func makeJoinURL(inviteCode: String) throws -> URL
    func inviteCode(from url: URL) -> String?
}

enum BeloteJoinLinkError: Error, Equatable, LocalizedError {
    case invalidInviteCode
    case invalidJoinURL

    var errorDescription: String? {
        switch self {
        case .invalidInviteCode:
            return "Le code de partage est vide."
        case .invalidJoinURL:
            return "Le lien de partage ne peut pas etre genere."
        }
    }
}

struct StandardBeloteJoinLinkService: BeloteJoinLinkService {
    private let scheme = "belote"
    private let host = "join"
    private let codeQueryItemName = "code"

    func makeJoinURL(inviteCode: String) throws -> URL {
        let normalizedInviteCode = normalize(inviteCode)
        guard !normalizedInviteCode.isEmpty else {
            throw BeloteJoinLinkError.invalidInviteCode
        }

        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [
            URLQueryItem(name: codeQueryItemName, value: normalizedInviteCode)
        ]

        guard let url = components.url else {
            throw BeloteJoinLinkError.invalidJoinURL
        }

        return url
    }

    func inviteCode(from url: URL) -> String? {
        guard url.scheme == scheme,
              url.host == host,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let inviteCode = components.queryItems?.first(where: { $0.name == codeQueryItemName })?.value else {
            return nil
        }

        let normalizedInviteCode = normalize(inviteCode)
        return normalizedInviteCode.isEmpty ? nil : normalizedInviteCode
    }

    private func normalize(_ inviteCode: String) -> String {
        inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
