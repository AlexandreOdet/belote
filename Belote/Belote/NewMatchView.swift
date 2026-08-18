//
//  NewMatchView.swift
//  Belote
//
//  Created by Alexandre Odet on 06/08/2026.
//

import SwiftUI

struct NewMatchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var teamAName = "Nous"
    @State private var teamBName = "Eux"
    @State private var teamAPlayerOneName = "Joueur 1"
    @State private var teamAPlayerTwoName = "Joueur 3"
    @State private var teamBPlayerOneName = "Joueur 2"
    @State private var teamBPlayerTwoName = "Joueur 4"
    @State private var firstDealerSeat = BelotePlayerSeat.teamAPlayerOne
    @State private var targetScore = 1_000

    let onCreate: (BeloteMatch) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(sanitized(teamAName, fallback: "Nous")) vs \(sanitized(teamBName, fallback: "Eux"))")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Objectif \(targetScore) points, premier donneur \(playerName(for: firstDealerSeat)).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                Section("Equipes") {
                    TextField("Nom equipe 1", text: $teamAName)
                    TextField("Nom equipe 2", text: $teamBName)
                }

                Section("Composition") {
                    VStack(alignment: .leading, spacing: 12) {
                        TeamPlayersEditor(
                            teamName: sanitized(teamAName, fallback: "Nous"),
                            firstPlayerName: $teamAPlayerOneName,
                            secondPlayerName: $teamAPlayerTwoName,
                            firstPlayerPlaceholder: "Joueur 1",
                            secondPlayerPlaceholder: "Joueur 3"
                        )

                        Divider()

                        TeamPlayersEditor(
                            teamName: sanitized(teamBName, fallback: "Eux"),
                            firstPlayerName: $teamBPlayerOneName,
                            secondPlayerName: $teamBPlayerTwoName,
                            firstPlayerPlaceholder: "Joueur 2",
                            secondPlayerPlaceholder: "Joueur 4"
                        )
                    }
                    .padding(.vertical, 4)
                }

                Section("Parametres") {
                    Picker("Premier donneur", selection: $firstDealerSeat) {
                        ForEach(BelotePlayerSeat.allCases) { seat in
                            Text(playerName(for: seat))
                                .tag(seat)
                        }
                    }

                    Stepper(value: $targetScore, in: 500...3_000, step: 100) {
                        LabeledContent("Objectif", value: "\(targetScore) points")
                    }
                }
            }
            .navigationTitle("Nouvelle partie")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        onCreate(
                            BeloteMatch(
                                teamAName: sanitized(teamAName, fallback: "Nous"),
                                teamBName: sanitized(teamBName, fallback: "Eux"),
                                teamAPlayerOneName: sanitized(teamAPlayerOneName, fallback: "Joueur 1"),
                                teamAPlayerTwoName: sanitized(teamAPlayerTwoName, fallback: "Joueur 3"),
                                teamBPlayerOneName: sanitized(teamBPlayerOneName, fallback: "Joueur 2"),
                                teamBPlayerTwoName: sanitized(teamBPlayerTwoName, fallback: "Joueur 4"),
                                firstDealerSeat: firstDealerSeat,
                                targetScore: targetScore
                            )
                        )
                        dismiss()
                    }
                }
            }
        }
    }

    private func sanitized(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func playerName(for seat: BelotePlayerSeat) -> String {
        switch seat {
        case .teamAPlayerOne:
            return sanitized(teamAPlayerOneName, fallback: "Joueur 1")
        case .teamAPlayerTwo:
            return sanitized(teamAPlayerTwoName, fallback: "Joueur 3")
        case .teamBPlayerOne:
            return sanitized(teamBPlayerOneName, fallback: "Joueur 2")
        case .teamBPlayerTwo:
            return sanitized(teamBPlayerTwoName, fallback: "Joueur 4")
        }
    }
}

struct TeamPlayersEditor: View {
    let teamName: String
    @Binding var firstPlayerName: String
    @Binding var secondPlayerName: String
    let firstPlayerPlaceholder: String
    let secondPlayerPlaceholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(teamName, systemImage: "person.2.fill")
                .font(.subheadline)
                .fontWeight(.semibold)

            TextField(firstPlayerPlaceholder, text: $firstPlayerName)
            TextField(secondPlayerPlaceholder, text: $secondPlayerName)
        }
    }
}
