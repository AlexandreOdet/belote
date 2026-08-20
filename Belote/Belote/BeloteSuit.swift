//
//  BeloteSuit.swift
//  Belote
//
//  Created by Alexandre Odet on 30/07/2026.
//

import Foundation

enum BeloteSuit: String, CaseIterable, Codable, Identifiable {
    case clubs
    case diamonds
    case hearts
    case spades
    case noTrump
    case allTrump

    var id: String { rawValue }

    var cardSuit: BeloteCardSuit? {
        switch self {
        case .clubs:
            return .clubs
        case .diamonds:
            return .diamonds
        case .hearts:
            return .hearts
        case .spades:
            return .spades
        case .noTrump, .allTrump:
            return nil
        }
    }

    var title: String {
        switch self {
        case .clubs:
            return "Trefle"
        case .diamonds:
            return "Carreau"
        case .hearts:
            return "Coeur"
        case .spades:
            return "Pique"
        case .noTrump:
            return "Sans atout"
        case .allTrump:
            return "Tout atout"
        }
    }

    var symbol: String {
        switch self {
        case .clubs:
            return "suit.club.fill"
        case .diamonds:
            return "suit.diamond.fill"
        case .hearts:
            return "suit.heart.fill"
        case .spades:
            return "suit.spade.fill"
        case .noTrump:
            return "circle.slash"
        case .allTrump:
            return "star.fill"
        }
    }
}
