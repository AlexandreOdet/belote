//
//  CardReferenceView.swift
//  Belote
//
//  Created by Alexandre Odet on 06/08/2026.
//

import SwiftUI

struct CardReferenceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.beloteDependencies) private var dependencies
    @State private var selectedContract = BeloteSuit.hearts

    private let columns = [
        GridItem(.adaptive(minimum: 68), spacing: 8)
    ]

    init(defaultGameMode: BeloteGameMode) {
        _selectedContract = State(initialValue: defaultGameMode.contract)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Contrat") {
                    Picker("Atout", selection: $selectedContract) {
                        ForEach(BeloteSuit.allCases) { suit in
                            Label(suit.title, systemImage: suit.symbol)
                                .tag(suit)
                        }
                    }

                    LabeledContent("Points cartes", value: "\(dependencies.cardValueService.cardPointsTotal(in: gameMode))")
                    LabeledContent("Avec dix de der", value: "\(dependencies.cardValueService.cardPointsTotal(in: gameMode) + 10)")
                }

                ForEach(BeloteCardSuit.allCases) { suit in
                    Section {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(dependencies.cardValueService.cards(in: suit, mode: gameMode)) { card in
                                CardValueTile(card: card, mode: gameMode, cardValueService: dependencies.cardValueService)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Label(suit.title, systemImage: suit.symbol)
                    }
                }
            }
            .navigationTitle("Cartes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var gameMode: BeloteGameMode {
        .standard(contract: selectedContract)
    }
}

struct CardValueTile: View {
    let card: BeloteCard
    let mode: BeloteGameMode
    let cardValueService: any BeloteCardValueService

    private var isTrump: Bool {
        mode.contract == .allTrump || card.suit == mode.contract.cardSuit
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text(card.rank.shortTitle)
                    .font(.headline)
                Image(systemName: card.suit.symbol)
                    .font(.caption)
            }
            .foregroundStyle(isTrump ? .primary : .secondary)

            Text("\(cardValueService.value(of: card, in: mode))")
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(isTrump ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
