//
//  BeloteCard.swift
//  Belote
//
//  Created by Alexandre Odet on 30/07/2026.
//

import Foundation

enum BeloteCardSuit: String, CaseIterable, Codable, Identifiable {
    case clubs
    case diamonds
    case hearts
    case spades

    var id: String { rawValue }

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
        }
    }
}

enum BeloteCardRank: String, CaseIterable, Codable, Identifiable {
    case seven
    case eight
    case nine
    case jack
    case queen
    case king
    case ten
    case ace

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .seven:
            return "7"
        case .eight:
            return "8"
        case .nine:
            return "9"
        case .jack:
            return "V"
        case .queen:
            return "D"
        case .king:
            return "R"
        case .ten:
            return "10"
        case .ace:
            return "A"
        }
    }
}

struct BeloteCard: Codable, Hashable, Identifiable {
    let suit: BeloteCardSuit
    let rank: BeloteCardRank

    var id: String {
        "\(suit.rawValue)-\(rank.rawValue)"
    }

    var title: String {
        "\(rank.shortTitle) \(suit.title)"
    }
}

enum BeloteDeck {
    static let cards: [BeloteCard] = BeloteCardSuit.allCases.flatMap { suit in
        BeloteCardRank.allCases.map { rank in
            BeloteCard(suit: suit, rank: rank)
        }
    }
}
