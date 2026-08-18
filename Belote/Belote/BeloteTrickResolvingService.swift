//
//  BeloteTrickResolvingService.swift
//  Belote
//
//  Created by Alexandre Odet on 06/08/2026.
//

import Foundation

protocol BeloteTrickResolvingService {
    func resolve(_ trick: BeloteTrick, mode: BeloteGameMode, cardValueService: any BeloteCardValueService) throws -> BeloteTrickResult
}

enum BeloteTrickResolvingError: Error, Equatable, LocalizedError {
    case incompleteTrick(expected: Int, actual: Int)
    case invalidLeadingSeat(expected: BelotePlayerSeat, actual: BelotePlayerSeat)
    case duplicateSeat(BelotePlayerSeat)
    case duplicateCard(BeloteCard)

    var errorDescription: String? {
        switch self {
        case let .incompleteTrick(expected, actual):
            return "Le pli doit contenir \(expected) cartes, pas \(actual)."
        case let .invalidLeadingSeat(expected, actual):
            return "Le premier joueur du pli doit etre \(expected), pas \(actual)."
        case .duplicateSeat:
            return "Un joueur ne peut pas jouer deux cartes dans le meme pli."
        case .duplicateCard:
            return "La meme carte ne peut pas etre jouee deux fois."
        }
    }
}

struct StandardBeloteTrickResolvingService: BeloteTrickResolvingService {
    func resolve(_ trick: BeloteTrick, mode: BeloteGameMode, cardValueService: any BeloteCardValueService) throws -> BeloteTrickResult {
        try validate(trick)

        guard let leadingCard = trick.playedCards.first else {
            throw BeloteTrickResolvingError.incompleteTrick(expected: BelotePlayerSeat.allCases.count, actual: 0)
        }

        let winningPlay = trick.playedCards.dropFirst().reduce(leadingCard) { currentWinner, playedCard in
            isWinning(playedCard, over: currentWinner, leadingSuit: leadingCard.card.suit, mode: mode, cardValueService: cardValueService) ? playedCard : currentWinner
        }
        let points = trick.playedCards.reduce(0) { total, playedCard in
            total + cardValueService.value(of: playedCard.card, in: mode)
        }

        return BeloteTrickResult(
            winningSeat: winningPlay.seat,
            winningTeam: winningPlay.seat.team,
            points: points,
            leadingSuit: leadingCard.card.suit
        )
    }

    private func validate(_ trick: BeloteTrick) throws {
        let expectedCount = BelotePlayerSeat.allCases.count
        guard trick.playedCards.count == expectedCount else {
            throw BeloteTrickResolvingError.incompleteTrick(expected: expectedCount, actual: trick.playedCards.count)
        }

        guard let firstSeat = trick.playedCards.first?.seat, firstSeat == trick.leaderSeat else {
            throw BeloteTrickResolvingError.invalidLeadingSeat(expected: trick.leaderSeat, actual: trick.playedCards.first?.seat ?? trick.leaderSeat.next)
        }

        var seenSeats = Set<BelotePlayerSeat>()
        var seenCards = Set<BeloteCard>()

        for playedCard in trick.playedCards {
            guard seenSeats.insert(playedCard.seat).inserted else {
                throw BeloteTrickResolvingError.duplicateSeat(playedCard.seat)
            }

            guard seenCards.insert(playedCard.card).inserted else {
                throw BeloteTrickResolvingError.duplicateCard(playedCard.card)
            }
        }
    }

    private func isWinning(
        _ candidate: BelotePlayedCard,
        over currentWinner: BelotePlayedCard,
        leadingSuit: BeloteCardSuit,
        mode: BeloteGameMode,
        cardValueService: any BeloteCardValueService
    ) -> Bool {
        let trumpSuit = mode.contract.cardSuit
        let candidateIsTrump = isTrump(candidate.card, trumpSuit: trumpSuit, mode: mode)
        let currentIsTrump = isTrump(currentWinner.card, trumpSuit: trumpSuit, mode: mode)

        if candidateIsTrump != currentIsTrump {
            return candidateIsTrump
        }

        guard candidate.card.suit == currentWinner.card.suit else {
            return !currentIsTrump && candidate.card.suit == leadingSuit
        }

        return cardValueService.power(of: candidate.card, in: mode) > cardValueService.power(of: currentWinner.card, in: mode)
    }

    private func isTrump(_ card: BeloteCard, trumpSuit: BeloteCardSuit?, mode: BeloteGameMode) -> Bool {
        switch mode.contract {
        case .allTrump:
            return true
        case .noTrump:
            return false
        case .clubs, .diamonds, .hearts, .spades:
            return card.suit == trumpSuit
        }
    }
}
