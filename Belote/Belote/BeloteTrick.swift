//
//  BeloteTrick.swift
//  Belote
//
//  Created by Alexandre Odet on 06/08/2026.
//

import Foundation

struct BelotePlayedCard: Hashable, Identifiable {
    let seat: BelotePlayerSeat
    let card: BeloteCard

    var id: String {
        "\(seat.rawValue)-\(card.id)"
    }
}

struct BeloteTrick: Equatable {
    let leaderSeat: BelotePlayerSeat
    let playedCards: [BelotePlayedCard]

    init(leaderSeat: BelotePlayerSeat, playedCards: [BelotePlayedCard] = []) {
        self.leaderSeat = leaderSeat
        self.playedCards = playedCards
    }

    var leadingSuit: BeloteCardSuit? {
        playedCards.first?.card.suit
    }

    var isComplete: Bool {
        playedCards.count == BelotePlayerSeat.allCases.count
    }
}

struct BeloteTrickResult: Equatable {
    let winningSeat: BelotePlayerSeat
    let winningTeam: BeloteTeam
    let points: Int
    let leadingSuit: BeloteCardSuit
}
