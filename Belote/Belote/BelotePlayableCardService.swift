//
//  BelotePlayableCardService.swift
//  Belote
//
//  Created by Alexandre Odet on 14/08/2026.
//

import Foundation

protocol BelotePlayableCardService {
    func playableCards(
        in hand: [BeloteCard],
        for seat: BelotePlayerSeat,
        currentTrick: BeloteTrick,
        mode: BeloteGameMode,
        cardValueService: any BeloteCardValueService
    ) -> [BeloteCard]
}

struct StandardBelotePlayableCardService: BelotePlayableCardService {
    func playableCards(
        in hand: [BeloteCard],
        for seat: BelotePlayerSeat,
        currentTrick: BeloteTrick,
        mode: BeloteGameMode,
        cardValueService: any BeloteCardValueService
    ) -> [BeloteCard] {
        guard let leadingSuit = currentTrick.leadingSuit,
              let currentWinner = currentWinner(in: currentTrick, mode: mode, cardValueService: cardValueService) else {
            return hand
        }

        let matchingSuitCards = hand.filter { $0.suit == leadingSuit }
        if !matchingSuitCards.isEmpty {
            guard isTrumpSuit(leadingSuit, mode: mode) else {
                return matchingSuitCards
            }

            return requiredTrumpCards(from: matchingSuitCards, currentTrick: currentTrick, mode: mode, cardValueService: cardValueService)
        }

        if currentWinner.seat.team == seat.team {
            return hand
        }

        let trumpCards = hand.filter { isTrump($0, mode: mode) }
        guard !trumpCards.isEmpty else {
            return hand
        }

        return requiredTrumpCards(from: trumpCards, currentTrick: currentTrick, mode: mode, cardValueService: cardValueService)
    }

    private func requiredTrumpCards(
        from cards: [BeloteCard],
        currentTrick: BeloteTrick,
        mode: BeloteGameMode,
        cardValueService: any BeloteCardValueService
    ) -> [BeloteCard] {
        guard let strongestTrump = strongestTrump(in: currentTrick.playedCards, mode: mode, cardValueService: cardValueService) else {
            return cards
        }

        let strongerCards = cards.filter {
            cardValueService.power(of: $0, in: mode) > cardValueService.power(of: strongestTrump.card, in: mode)
        }

        return strongerCards.isEmpty ? cards : strongerCards
    }

    private func currentWinner(
        in trick: BeloteTrick,
        mode: BeloteGameMode,
        cardValueService: any BeloteCardValueService
    ) -> BelotePlayedCard? {
        guard let leadingCard = trick.playedCards.first else {
            return nil
        }

        return trick.playedCards.dropFirst().reduce(leadingCard) { currentWinner, playedCard in
            isWinning(playedCard, over: currentWinner, leadingSuit: leadingCard.card.suit, mode: mode, cardValueService: cardValueService) ? playedCard : currentWinner
        }
    }

    private func strongestTrump(
        in playedCards: [BelotePlayedCard],
        mode: BeloteGameMode,
        cardValueService: any BeloteCardValueService
    ) -> BelotePlayedCard? {
        playedCards
            .filter { isTrump($0.card, mode: mode) }
            .max { first, second in
                cardValueService.power(of: first.card, in: mode) < cardValueService.power(of: second.card, in: mode)
            }
    }

    private func isWinning(
        _ candidate: BelotePlayedCard,
        over currentWinner: BelotePlayedCard,
        leadingSuit: BeloteCardSuit,
        mode: BeloteGameMode,
        cardValueService: any BeloteCardValueService
    ) -> Bool {
        let candidateIsTrump = isTrump(candidate.card, mode: mode)
        let currentIsTrump = isTrump(currentWinner.card, mode: mode)

        if candidateIsTrump != currentIsTrump {
            return candidateIsTrump
        }

        guard candidate.card.suit == currentWinner.card.suit else {
            return !currentIsTrump && candidate.card.suit == leadingSuit
        }

        return cardValueService.power(of: candidate.card, in: mode) > cardValueService.power(of: currentWinner.card, in: mode)
    }

    private func isTrumpSuit(_ suit: BeloteCardSuit, mode: BeloteGameMode) -> Bool {
        switch mode.contract {
        case .allTrump:
            return true
        case .noTrump:
            return false
        case .clubs, .diamonds, .hearts, .spades:
            return suit == mode.contract.cardSuit
        }
    }

    private func isTrump(_ card: BeloteCard, mode: BeloteGameMode) -> Bool {
        switch mode.contract {
        case .allTrump:
            return true
        case .noTrump:
            return false
        case .clubs, .diamonds, .hearts, .spades:
            return card.suit == mode.contract.cardSuit
        }
    }
}
