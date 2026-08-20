//
//  RoundPlaySectionView.swift
//  Belote
//
//  Created by Alexandre Odet on 10/08/2026.
//

import SwiftUI

struct RoundPlaySectionView: View {
    let match: BeloteMatch
    let session: BeloteRoundPlaySession
    let cardValueService: any BeloteCardValueService
    let playableCardService: any BelotePlayableCardService
    let errorMessage: String?
    let onPlayCard: (BelotePlayerSeat, BeloteCard) -> Void
    let onConfirmRound: () -> Void

    var body: some View {
        Section("Jeu") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("À jouer: \(match.displayName(for: session.currentSeat))", systemImage: "hand.point.up.left.fill")
                    Spacer()
                    Text("Pli \(min(session.completedTricks.count + 1, 8))/8")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                HStack(spacing: 12) {
                    ScorePill(name: match.teamAName, score: session.teamATrickPoints)
                    ScorePill(name: match.teamBName, score: session.teamBTrickPoints)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Donneur: \(match.displayName(for: session.completedDeal.dealerSeat))", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        Label("Preneur: \(match.displayName(for: session.completedDeal.takerSeat))", systemImage: "person.fill.checkmark")
                    }

                    HStack {
                        Label(session.completedDeal.trump.title, systemImage: session.completedDeal.trump.symbol)
                        Spacer()
                        HStack(spacing: 6) {
                            Text("Retourne")
                            PlayCardBadge(card: session.completedDeal.turnedCard)
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !session.currentPlayedCards.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pli en cours")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            ForEach(session.currentPlayedCards) { playedCard in
                                PlayedCardBadge(match: match, playedCard: playedCard)
                            }
                        }
                    }
                }

                if let lastTrick = session.completedTricks.last {
                    Text("Dernier pli: \(match.displayName(for: lastTrick.result.winningSeat)) +\(lastTrick.result.points)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let beloteTeam = session.beloteTeam {
                    Label("Belote/Rebelote \(match.displayName(for: beloteTeam))", systemImage: "suit.heart.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !session.completedTricks.isEmpty {
                    CompletedTricksView(match: match, tricks: session.completedTricks)
                }

                if session.isComplete {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Manche terminee", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)

                        Button {
                            onConfirmRound()
                        } label: {
                            Label("Ajouter au score", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 6)

            ForEach(session.hands) { hand in
                VStack(alignment: .leading, spacing: 8) {
                    Text(match.displayName(for: hand.seat))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(hand.cards) { card in
                                let canPlay = isPlayable(card, in: hand)
                                Button {
                                    onPlayCard(hand.seat, card)
                                } label: {
                                    PlayCardBadge(card: card)
                                }
                                .buttonStyle(.plain)
                                .disabled(!canPlay)
                                .opacity(canPlay ? 1 : 0.35)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func isPlayable(_ card: BeloteCard, in hand: BeloteHand) -> Bool {
        guard hand.seat == session.currentSeat && !session.isComplete else {
            return false
        }

        let playableCards = playableCardService.playableCards(
            in: hand.cards,
            for: hand.seat,
            currentTrick: session.currentTrick,
            mode: .standard(contract: session.completedDeal.trump),
            cardValueService: cardValueService
        )

        return playableCards.contains(card)
    }
}

private struct PlayCardBadge: View {
    let card: BeloteCard

    var body: some View {
        HStack(spacing: 4) {
            Text(card.rank.shortTitle)
                .fontWeight(.semibold)
            Image(systemName: card.suit.symbol)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.accentColor.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct PlayedCardBadge: View {
    let match: BeloteMatch
    let playedCard: BelotePlayedCard

    var body: some View {
        VStack(spacing: 4) {
            PlayCardBadge(card: playedCard.card)
            Text(match.displayName(for: playedCard.seat))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CompletedTricksView: View {
    let match: BeloteMatch
    let tricks: [BeloteCompletedTrick]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Plis gagnes")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(tricks) { trick in
                HStack {
                    Text("Pli \(trick.index)")
                    Spacer()
                    Text(match.displayName(for: trick.result.winningSeat))
                    Text("+\(trick.result.points)")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
