//
//  BeloteRoundPlayService.swift
//  Belote
//
//  Created by Alexandre Odet on 10/08/2026.
//

import Foundation

struct BeloteCompletedTrick: Codable, Equatable, Identifiable {
    let index: Int
    let trick: BeloteTrick
    let result: BeloteTrickResult

    var id: Int { index }
}

struct BeloteRoundPlaySession: Codable, Equatable {
    let completedDeal: BeloteCompletedDeal
    var hands: [BeloteHand]
    var currentLeaderSeat: BelotePlayerSeat
    var currentSeat: BelotePlayerSeat
    var currentPlayedCards: [BelotePlayedCard]
    var completedTricks: [BeloteCompletedTrick]
    var teamATrickPoints: Int
    var teamBTrickPoints: Int
    var beloteTeam: BeloteTeam?

    var isComplete: Bool {
        completedTricks.count == 8
    }

    var currentTrick: BeloteTrick {
        BeloteTrick(leaderSeat: currentLeaderSeat, playedCards: currentPlayedCards)
    }

    func hand(for seat: BelotePlayerSeat) -> [BeloteCard] {
        hands.first { $0.seat == seat }?.cards ?? []
    }
}

protocol BeloteRoundPlayService {
    func startSession(from completedDeal: BeloteCompletedDeal) -> BeloteRoundPlaySession
    func play(
        card: BeloteCard,
        for seat: BelotePlayerSeat,
        in session: BeloteRoundPlaySession,
        cardValueService: any BeloteCardValueService,
        trickResolvingService: any BeloteTrickResolvingService,
        playableCardService: any BelotePlayableCardService
    ) throws -> BeloteRoundPlaySession
}

enum BeloteRoundPlayError: Error, Equatable, LocalizedError {
    case roundAlreadyComplete
    case notCurrentPlayer(expected: BelotePlayerSeat, actual: BelotePlayerSeat)
    case cardNotInHand(BeloteCard, BelotePlayerSeat)
    case cardNotPlayable(BeloteCard)

    var errorDescription: String? {
        switch self {
        case .roundAlreadyComplete:
            return "La manche est déjà terminée."
        case let .notCurrentPlayer(expected, actual):
            return "C'est à \(expected) de jouer, pas à \(actual)."
        case .cardNotInHand:
            return "Cette carte n'est pas dans la main du joueur."
        case .cardNotPlayable:
            return "Cette carte ne respecte pas les règles du pli."
        }
    }
}

struct StandardBeloteRoundPlayService: BeloteRoundPlayService {
    func startSession(from completedDeal: BeloteCompletedDeal) -> BeloteRoundPlaySession {
        let firstSeat = completedDeal.dealerSeat.next

        return BeloteRoundPlaySession(
            completedDeal: completedDeal,
            hands: completedDeal.hands,
            currentLeaderSeat: firstSeat,
            currentSeat: firstSeat,
            currentPlayedCards: [],
            completedTricks: [],
            teamATrickPoints: 0,
            teamBTrickPoints: 0,
            beloteTeam: nil
        )
    }

    func play(
        card: BeloteCard,
        for seat: BelotePlayerSeat,
        in session: BeloteRoundPlaySession,
        cardValueService: any BeloteCardValueService,
        trickResolvingService: any BeloteTrickResolvingService,
        playableCardService: any BelotePlayableCardService
    ) throws -> BeloteRoundPlaySession {
        guard !session.isComplete else {
            throw BeloteRoundPlayError.roundAlreadyComplete
        }

        guard seat == session.currentSeat else {
            throw BeloteRoundPlayError.notCurrentPlayer(expected: session.currentSeat, actual: seat)
        }

        let playableCards = playableCardService.playableCards(
            in: session.hand(for: seat),
            for: seat,
            currentTrick: session.currentTrick,
            mode: .standard(contract: session.completedDeal.trump),
            cardValueService: cardValueService
        )
        guard playableCards.contains(card) else {
            throw BeloteRoundPlayError.cardNotPlayable(card)
        }

        var nextSession = session
        if nextSession.beloteTeam == nil,
           hasBeloteRebelote(card: card, in: session.hand(for: seat), trump: session.completedDeal.trump) {
            nextSession.beloteTeam = seat.team
        }

        try remove(card: card, from: seat, in: &nextSession)
        nextSession.currentPlayedCards.append(BelotePlayedCard(seat: seat, card: card))

        guard nextSession.currentPlayedCards.count == BelotePlayerSeat.allCases.count else {
            nextSession.currentSeat = seat.next
            return nextSession
        }

        let trick = BeloteTrick(leaderSeat: nextSession.currentLeaderSeat, playedCards: nextSession.currentPlayedCards)
        var result = try trickResolvingService.resolve(
            trick,
            mode: .standard(contract: nextSession.completedDeal.trump),
            cardValueService: cardValueService
        )

        if nextSession.completedTricks.count == 7 {
            result = BeloteTrickResult(
                winningSeat: result.winningSeat,
                winningTeam: result.winningTeam,
                points: result.points + 10,
                leadingSuit: result.leadingSuit
            )
        }

        nextSession.completedTricks.append(
            BeloteCompletedTrick(index: nextSession.completedTricks.count + 1, trick: trick, result: result)
        )
        add(points: result.points, to: result.winningTeam, in: &nextSession)
        nextSession.currentPlayedCards = []
        nextSession.currentLeaderSeat = result.winningSeat
        nextSession.currentSeat = result.winningSeat

        return nextSession
    }

    private func remove(card: BeloteCard, from seat: BelotePlayerSeat, in session: inout BeloteRoundPlaySession) throws {
        guard let handIndex = session.hands.firstIndex(where: { $0.seat == seat }) else {
            throw BeloteRoundPlayError.cardNotInHand(card, seat)
        }

        var cards = session.hands[handIndex].cards
        guard let cardIndex = cards.firstIndex(of: card) else {
            throw BeloteRoundPlayError.cardNotInHand(card, seat)
        }

        cards.remove(at: cardIndex)
        session.hands[handIndex] = BeloteHand(seat: seat, cards: cards)
    }

    private func add(points: Int, to team: BeloteTeam, in session: inout BeloteRoundPlaySession) {
        switch team {
        case .teamA:
            session.teamATrickPoints += points
        case .teamB:
            session.teamBTrickPoints += points
        }
    }

    private func hasBeloteRebelote(card: BeloteCard, in hand: [BeloteCard], trump: BeloteSuit) -> Bool {
        guard let trumpSuit = trump.cardSuit,
              card.suit == trumpSuit,
              card.rank == .king || card.rank == .queen else {
            return false
        }

        let requiredRank: BeloteCardRank = card.rank == .king ? .queen : .king
        return hand.contains(BeloteCard(suit: trumpSuit, rank: requiredRank))
    }
}
