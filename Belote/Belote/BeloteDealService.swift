//
//  BeloteDealService.swift
//  Belote
//
//  Created by Alexandre Odet on 06/08/2026.
//

import Foundation

struct BeloteHand: Codable, Equatable, Identifiable {
    let seat: BelotePlayerSeat
    let cards: [BeloteCard]

    var id: Int { seat.rawValue }
}

struct BeloteInitialDeal: Codable, Equatable {
    let dealerSeat: BelotePlayerSeat
    let hands: [BeloteHand]
    let turnedCard: BeloteCard
    let remainingDeck: [BeloteCard]

    var proposedTrump: BeloteSuit {
        BeloteSuit(cardSuit: turnedCard.suit)
    }

    func hand(for seat: BelotePlayerSeat) -> [BeloteCard] {
        hands.first { $0.seat == seat }?.cards ?? []
    }
}

struct BeloteCompletedDeal: Codable, Equatable {
    let dealerSeat: BelotePlayerSeat
    let takerSeat: BelotePlayerSeat
    let trump: BeloteSuit
    let turnedCard: BeloteCard
    let hands: [BeloteHand]

    var takerTeam: BeloteTeam {
        takerSeat.team
    }

    func hand(for seat: BelotePlayerSeat) -> [BeloteCard] {
        hands.first { $0.seat == seat }?.cards ?? []
    }
}

enum BeloteContractSelection: Equatable {
    case firstRound(takerSeat: BelotePlayerSeat)
    case secondRound(takerSeat: BelotePlayerSeat, trump: BeloteSuit)

    var takerSeat: BelotePlayerSeat {
        switch self {
        case let .firstRound(takerSeat), let .secondRound(takerSeat, _):
            return takerSeat
        }
    }
}

protocol BeloteDealService {
    func startDeal(dealerSeat: BelotePlayerSeat) -> BeloteInitialDeal
    func startDeal<RNG: RandomNumberGenerator>(dealerSeat: BelotePlayerSeat, randomGenerator: inout RNG) -> BeloteInitialDeal
    func completeDeal(_ initialDeal: BeloteInitialDeal, selection: BeloteContractSelection) throws -> BeloteCompletedDeal
}

enum BeloteDealError: Error, Equatable, LocalizedError {
    case invalidSecondRoundTrump(BeloteSuit)

    var errorDescription: String? {
        switch self {
        case let .invalidSecondRoundTrump(trump):
            return "L'atout \(trump.title) n'est pas valide au second tour."
        }
    }
}

struct StandardBeloteDealService: BeloteDealService {
    func startDeal(dealerSeat: BelotePlayerSeat) -> BeloteInitialDeal {
        var randomGenerator = SystemRandomNumberGenerator()
        return startDeal(dealerSeat: dealerSeat, randomGenerator: &randomGenerator)
    }

    func startDeal<RNG: RandomNumberGenerator>(dealerSeat: BelotePlayerSeat, randomGenerator: inout RNG) -> BeloteInitialDeal {
        let shuffledDeck = BeloteDeck.cards.shuffled(using: &randomGenerator)
        let seats = dealingOrder(after: dealerSeat)
        var hands = emptyHands(for: seats)
        var cursor = 0

        for seat in seats {
            hands[seat, default: []].append(contentsOf: shuffledDeck[cursor..<cursor + 3])
            cursor += 3
        }

        for seat in seats {
            hands[seat, default: []].append(contentsOf: shuffledDeck[cursor..<cursor + 2])
            cursor += 2
        }

        let turnedCard = shuffledDeck[cursor]
        cursor += 1

        return BeloteInitialDeal(
            dealerSeat: dealerSeat,
            hands: seats.map { BeloteHand(seat: $0, cards: hands[$0] ?? []) },
            turnedCard: turnedCard,
            remainingDeck: Array(shuffledDeck[cursor...])
        )
    }

    func completeDeal(_ initialDeal: BeloteInitialDeal, selection: BeloteContractSelection) throws -> BeloteCompletedDeal {
        let trump = try trumpSuit(for: selection, turnedCard: initialDeal.turnedCard)
        let seats = dealingOrder(after: initialDeal.dealerSeat)
        var hands = Dictionary(uniqueKeysWithValues: initialDeal.hands.map { ($0.seat, $0.cards) })
        var cursor = 0

        hands[selection.takerSeat, default: []].append(initialDeal.turnedCard)

        for seat in seats {
            let cardsToAdd = seat == selection.takerSeat ? 2 : 3
            hands[seat, default: []].append(contentsOf: initialDeal.remainingDeck[cursor..<cursor + cardsToAdd])
            cursor += cardsToAdd
        }

        return BeloteCompletedDeal(
            dealerSeat: initialDeal.dealerSeat,
            takerSeat: selection.takerSeat,
            trump: trump,
            turnedCard: initialDeal.turnedCard,
            hands: seats.map { BeloteHand(seat: $0, cards: hands[$0] ?? []) }
        )
    }

    private func trumpSuit(for selection: BeloteContractSelection, turnedCard: BeloteCard) throws -> BeloteSuit {
        switch selection {
        case .firstRound:
            return BeloteSuit(cardSuit: turnedCard.suit)
        case let .secondRound(_, trump):
            guard trump.cardSuit != nil && trump.cardSuit != turnedCard.suit else {
                throw BeloteDealError.invalidSecondRoundTrump(trump)
            }

            return trump
        }
    }

    private func dealingOrder(after dealerSeat: BelotePlayerSeat) -> [BelotePlayerSeat] {
        var seats: [BelotePlayerSeat] = []
        var seat = dealerSeat.next

        for _ in BelotePlayerSeat.allCases {
            seats.append(seat)
            seat = seat.next
        }

        return seats
    }

    private func emptyHands(for seats: [BelotePlayerSeat]) -> [BelotePlayerSeat: [BeloteCard]] {
        Dictionary(uniqueKeysWithValues: seats.map { ($0, []) })
    }
}

extension BeloteSuit {
    init(cardSuit: BeloteCardSuit) {
        switch cardSuit {
        case .clubs:
            self = .clubs
        case .diamonds:
            self = .diamonds
        case .hearts:
            self = .hearts
        case .spades:
            self = .spades
        }
    }
}
