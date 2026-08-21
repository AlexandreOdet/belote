//
//  BeloteMatchStateService.swift
//  Belote
//
//  Created by Alexandre Odet on 21/08/2026.
//

import Foundation

enum BeloteMatchState: Equatable {
    case readyForDeal(dealerSeat: BelotePlayerSeat)
    case choosingTrump(dealerSeat: BelotePlayerSeat, turnedCard: BeloteCard, proposedTrump: BeloteSuit)
    case readyToPlay(takerSeat: BelotePlayerSeat, trump: BeloteSuit)
    case playingRound(currentSeat: BelotePlayerSeat, trickNumber: Int, playedCardCount: Int)
    case roundReadyToScore(takerTeam: BeloteTeam, teamATrickPoints: Int, teamBTrickPoints: Int)
    case matchComplete(winningTeam: BeloteTeam)

    var title: String {
        switch self {
        case .readyForDeal:
            return "Pret a distribuer"
        case .choosingTrump:
            return "Choix de l'atout"
        case .readyToPlay:
            return "Pret a jouer"
        case .playingRound:
            return "Manche en cours"
        case .roundReadyToScore:
            return "Manche a scorer"
        case .matchComplete:
            return "Partie terminee"
        }
    }

    var systemImage: String {
        switch self {
        case .readyForDeal:
            return "rectangle.stack.badge.play"
        case .choosingTrump:
            return "suit.club.fill"
        case .readyToPlay:
            return "play.circle.fill"
        case .playingRound:
            return "hand.raised.fill"
        case .roundReadyToScore:
            return "checkmark.circle.fill"
        case .matchComplete:
            return "trophy.fill"
        }
    }
}

protocol BeloteMatchStateService {
    func state(
        for match: BeloteMatch,
        initialDeal: BeloteInitialDeal?,
        completedDeal: BeloteCompletedDeal?,
        playSession: BeloteRoundPlaySession?
    ) -> BeloteMatchState
}

struct StandardBeloteMatchStateService: BeloteMatchStateService {
    func state(
        for match: BeloteMatch,
        initialDeal: BeloteInitialDeal?,
        completedDeal: BeloteCompletedDeal?,
        playSession: BeloteRoundPlaySession?
    ) -> BeloteMatchState {
        if let playSession {
            if playSession.isComplete {
                return .roundReadyToScore(
                    takerTeam: playSession.completedDeal.takerTeam,
                    teamATrickPoints: playSession.teamATrickPoints,
                    teamBTrickPoints: playSession.teamBTrickPoints
                )
            }

            return .playingRound(
                currentSeat: playSession.currentSeat,
                trickNumber: playSession.completedTricks.count + 1,
                playedCardCount: playSession.currentPlayedCards.count
            )
        }

        if let completedDeal {
            return .readyToPlay(takerSeat: completedDeal.takerSeat, trump: completedDeal.trump)
        }

        if let initialDeal {
            return .choosingTrump(
                dealerSeat: initialDeal.dealerSeat,
                turnedCard: initialDeal.turnedCard,
                proposedTrump: initialDeal.proposedTrump
            )
        }

        if let winningTeam = match.winningTeam {
            return .matchComplete(winningTeam: winningTeam)
        }

        return .readyForDeal(dealerSeat: match.nextDealerSeat)
    }
}
