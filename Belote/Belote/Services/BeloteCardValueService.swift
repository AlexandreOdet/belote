//
//  BeloteCardValueService.swift
//  Belote
//
//  Created by Alexandre Odet on 06/08/2026.
//

import Foundation

struct BeloteGameMode: Equatable {
    let contract: BeloteSuit

    static func standard(contract: BeloteSuit) -> BeloteGameMode {
        BeloteGameMode(contract: contract)
    }
}

protocol BeloteCardValueService {
    func value(of card: BeloteCard, in mode: BeloteGameMode) -> Int
    func power(of card: BeloteCard, in mode: BeloteGameMode) -> Int
    func cards(in suit: BeloteCardSuit, mode: BeloteGameMode) -> [BeloteCard]
    func cardPointsTotal(in mode: BeloteGameMode) -> Int
}

struct StandardBeloteCardValueService: BeloteCardValueService {
    func value(of card: BeloteCard, in mode: BeloteGameMode) -> Int {
        switch mode.contract {
        case .allTrump:
            return trumpValue(for: card.rank)
        case .noTrump:
            return noTrumpValue(for: card.rank)
        case .clubs, .diamonds, .hearts, .spades:
            return card.suit == mode.contract.cardSuit ? trumpValue(for: card.rank) : nonTrumpValue(for: card.rank)
        }
    }

    func power(of card: BeloteCard, in mode: BeloteGameMode) -> Int {
        switch mode.contract {
        case .allTrump:
            return trumpStrength(for: card.rank)
        case .noTrump:
            return nonTrumpStrength(for: card.rank)
        case .clubs, .diamonds, .hearts, .spades:
            return card.suit == mode.contract.cardSuit ? trumpStrength(for: card.rank) : nonTrumpStrength(for: card.rank)
        }
    }

    func cards(in suit: BeloteCardSuit, mode: BeloteGameMode) -> [BeloteCard] {
        BeloteDeck.cards
            .filter { $0.suit == suit }
            .sorted { power(of: $0, in: mode) > power(of: $1, in: mode) }
    }

    func cardPointsTotal(in mode: BeloteGameMode) -> Int {
        BeloteDeck.cards.reduce(0) { total, card in
            total + value(of: card, in: mode)
        }
    }

    private func nonTrumpValue(for rank: BeloteCardRank) -> Int {
        switch rank {
        case .ace:
            return 11
        case .ten:
            return 10
        case .king:
            return 4
        case .queen:
            return 3
        case .jack:
            return 2
        case .nine, .eight, .seven:
            return 0
        }
    }

    private func trumpValue(for rank: BeloteCardRank) -> Int {
        switch rank {
        case .jack:
            return 20
        case .nine:
            return 14
        default:
            return nonTrumpValue(for: rank)
        }
    }

    private func noTrumpValue(for rank: BeloteCardRank) -> Int {
        switch rank {
        case .ace:
            return 19
        default:
            return nonTrumpValue(for: rank)
        }
    }

    private func nonTrumpStrength(for rank: BeloteCardRank) -> Int {
        switch rank {
        case .seven:
            return 0
        case .eight:
            return 1
        case .nine:
            return 2
        case .jack:
            return 3
        case .queen:
            return 4
        case .king:
            return 5
        case .ten:
            return 6
        case .ace:
            return 7
        }
    }

    private func trumpStrength(for rank: BeloteCardRank) -> Int {
        switch rank {
        case .seven:
            return 0
        case .eight:
            return 1
        case .queen:
            return 2
        case .king:
            return 3
        case .ten:
            return 4
        case .ace:
            return 5
        case .nine:
            return 6
        case .jack:
            return 7
        }
    }
}
