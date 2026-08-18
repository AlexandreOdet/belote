//
//  DealSectionView.swift
//  Belote
//
//  Created by Alexandre Odet on 07/08/2026.
//

import SwiftUI

enum TakingRoundOption: String, CaseIterable, Identifiable {
    case firstRound
    case secondRound

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstRound:
            return "1er tour"
        case .secondRound:
            return "2e tour"
        }
    }
}

struct DealSectionView: View {
    let match: BeloteMatch
    let initialDeal: BeloteInitialDeal?
    let completedDeal: BeloteCompletedDeal?
    @Binding var selectedTakingRound: TakingRoundOption
    @Binding var selectedTakerSeat: BelotePlayerSeat
    @Binding var selectedTrump: BeloteSuit
    let onStartDeal: () -> Void
    let onCompleteDeal: () -> Void

    var body: some View {
        Section("Distribution") {
            Button {
                onStartDeal()
            } label: {
                Label("Distribuer 5 cartes et retourner", systemImage: "rectangle.stack.badge.play")
            }

            if let initialDeal {
                InitialDealSummaryView(match: match, deal: initialDeal)

                Picker("Tour de prise", selection: $selectedTakingRound) {
                    ForEach(TakingRoundOption.allCases) { round in
                        Text(round.title)
                            .tag(round)
                    }
                }

                Picker("Preneur", selection: $selectedTakerSeat) {
                    ForEach(BelotePlayerSeat.allCases) { seat in
                        Text(match.displayName(for: seat))
                            .tag(seat)
                    }
                }

                if selectedTakingRound == .secondRound {
                    Picker("Atout choisi", selection: $selectedTrump) {
                        ForEach(availableSecondRoundTrumps(for: initialDeal)) { suit in
                            Label(suit.title, systemImage: suit.symbol)
                                .tag(suit)
                        }
                    }
                }

                Button {
                    onCompleteDeal()
                } label: {
                    Label("Valider la prise et compléter", systemImage: "checkmark.circle")
                }
            }

            if let completedDeal {
                CompletedDealSummaryView(match: match, deal: completedDeal)
            }
        }
    }

    private func availableSecondRoundTrumps(for deal: BeloteInitialDeal) -> [BeloteSuit] {
        BeloteSuit.allCases.filter { suit in
            suit.cardSuit != nil && suit != deal.proposedTrump
        }
    }
}

private struct InitialDealSummaryView: View {
    let match: BeloteMatch
    let deal: BeloteInitialDeal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Donneur: \(match.displayName(for: deal.dealerSeat))", systemImage: "arrow.triangle.2.circlepath")
                Spacer()
                Label(deal.proposedTrump.title, systemImage: deal.proposedTrump.symbol)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            LabeledContent("Retourne") {
                CardBadge(card: deal.turnedCard)
            }

            ForEach(deal.hands) { hand in
                HandRow(match: match, hand: hand)
            }

            Text("\(deal.remainingDeck.count) cartes à distribuer après la prise")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

private struct CompletedDealSummaryView: View {
    let match: BeloteMatch
    let deal: BeloteCompletedDeal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Preneur: \(match.displayName(for: deal.takerSeat))", systemImage: "person.fill.checkmark")
                Spacer()
                Label(deal.trump.title, systemImage: deal.trump.symbol)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ForEach(deal.hands) { hand in
                HandRow(match: match, hand: hand)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct HandRow: View {
    let match: BeloteMatch
    let hand: BeloteHand

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(match.displayName(for: hand.seat))
                .font(.subheadline)
                .fontWeight(.semibold)

            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(hand.cards) { card in
                        CardBadge(card: card)
                    }
                }
            }
        }
    }
}

private struct CardBadge: View {
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
        .background(Color.secondary.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
