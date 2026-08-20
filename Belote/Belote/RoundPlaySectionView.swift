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
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("À jouer", systemImage: "hand.point.up.left.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Pli \(min(session.completedTricks.count + 1, 8))/8")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(match.displayName(for: session.currentSeat))
                        .font(.title3)
                        .fontWeight(.semibold)

                    ProgressView(value: Double(session.completedTricks.count), total: 8)
                        .tint(.green)
                }

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
                    HStack {
                        Text(match.displayName(for: hand.seat))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if hand.seat == session.currentSeat && !session.isComplete {
                            Text("A jouer")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.16))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                        Spacer()
                        Text("\(hand.cards.count) cartes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(hand.cards) { card in
                                let canPlay = isPlayable(card, in: hand)
                                Button {
                                    onPlayCard(hand.seat, card)
                                } label: {
                                    PlayCardBadge(card: card, isPlayable: canPlay)
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
    var isPlayable = true

    var body: some View {
        VStack(spacing: 4) {
            Text(card.rank.shortTitle)
                .font(.headline)
                .fontWeight(.bold)
            Image(systemName: card.suit.symbol)
                .font(.title3)
                .foregroundStyle(suitColor)
        }
        .frame(width: 46, height: 58)
        .background(isPlayable ? Color.white : Color.secondary.opacity(0.08))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(isPlayable ? suitColor.opacity(0.45) : Color.secondary.opacity(0.20), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: isPlayable ? suitColor.opacity(0.12) : .clear, radius: 2, y: 1)
    }

    private var suitColor: Color {
        switch card.suit {
        case .clubs:
            return .green
        case .diamonds:
            return .orange
        case .hearts:
            return .red
        case .spades:
            return .primary
        }
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
