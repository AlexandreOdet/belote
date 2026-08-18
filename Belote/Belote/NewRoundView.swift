//
//  NewRoundView.swift
//  Belote
//
//  Created by Alexandre Odet on 06/08/2026.
//

import SwiftUI

struct NewRoundView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.beloteDependencies) private var dependencies
    let match: BeloteMatch
    let defaultGameMode: BeloteGameMode
    let onCreate: (BeloteRound) -> Void

    @State private var teamAPoints = 82
    @State private var teamBPoints = 80
    @State private var hasBelote = false
    @State private var beloteTeam = BeloteTeam.teamA
    @State private var isCapot = false
    @State private var capotTeam = BeloteTeam.teamA
    @State private var takerTeam = BeloteTeam.teamA
    @State private var trumpSuit = BeloteSuit.hearts
    @State private var scoringError: String?
    @State private var note = ""

    init(match: BeloteMatch, defaultGameMode: BeloteGameMode, onCreate: @escaping (BeloteRound) -> Void) {
        self.match = match
        self.defaultGameMode = defaultGameMode
        self.onCreate = onCreate
        _trumpSuit = State(initialValue: defaultGameMode.contract)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Points") {
                    TextField("\(match.teamAName)", value: $teamAPoints, format: .number)
#if os(iOS)
                        .keyboardType(.numberPad)
#endif
                    TextField("\(match.teamBName)", value: $teamBPoints, format: .number)
#if os(iOS)
                        .keyboardType(.numberPad)
#endif
                    Toggle("Belote / Rebelote", isOn: $hasBelote)
                    if hasBelote {
                        Picker("Equipe Belote", selection: $beloteTeam) {
                            ForEach(BeloteTeam.allCases) { team in
                                Text(match.displayName(for: team))
                                    .tag(team)
                            }
                        }
                    }
                    Toggle("Capot", isOn: $isCapot)
                    if isCapot {
                        Picker("Equipe capot", selection: $capotTeam) {
                            ForEach(BeloteTeam.allCases) { team in
                                Text(match.displayName(for: team))
                                    .tag(team)
                            }
                        }
                    }
                }

                Section("Contrat") {
                    Picker("Preneur", selection: $takerTeam) {
                        ForEach(BeloteTeam.allCases) { team in
                            Text(match.displayName(for: team))
                                .tag(team)
                        }
                    }
                    Picker("Atout", selection: $trumpSuit) {
                        ForEach(BeloteSuit.allCases) { suit in
                            Label(suit.title, systemImage: suit.symbol)
                                .tag(suit)
                        }
                    }
                    LabeledContent("Donneur", value: match.displayName(for: match.nextDealerSeat))
                }

                if let previewResult {
                    Section("Resultat") {
                        LabeledContent(match.teamAName, value: "\(previewResult.teamAPoints)")
                        LabeledContent(match.teamBName, value: "\(previewResult.teamBPoints)")
                        LabeledContent("Issue", value: previewResult.outcome.title)
                    }
                }

                Section {
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                if !isValidRound {
                    Section {
                        Label("Le total des plis doit faire \(BeloteScoring.baseRoundPoints) points.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }

                if let scoringError {
                    Section {
                        Label(scoringError, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Nouvelle manche")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        addRound()
                    }
                    .disabled(previewResult == nil)
                }
            }
            .onChange(of: hasBelote) { _, newValue in
                if newValue {
                    beloteTeam = takerTeam
                }
                refreshScoringError()
            }
            .onChange(of: teamAPoints) { _, newValue in
                let total = BeloteScoring.baseRoundPoints
                teamAPoints = clamped(newValue, total: total)
                teamBPoints = total - teamAPoints
                syncCapotPointsIfNeeded()
                refreshScoringError()
            }
            .onChange(of: teamBPoints) { _, newValue in
                let total = BeloteScoring.baseRoundPoints
                teamBPoints = clamped(newValue, total: total)
                teamAPoints = total - teamBPoints
                syncCapotPointsIfNeeded()
                refreshScoringError()
            }
            .onChange(of: isCapot) { _, _ in
                syncCapotPointsIfNeeded()
                refreshScoringError()
            }
            .onChange(of: capotTeam) { _, _ in
                syncCapotPointsIfNeeded()
                refreshScoringError()
            }
            .onChange(of: takerTeam) { _, newValue in
                if hasBelote {
                    beloteTeam = newValue
                }
                refreshScoringError()
            }
        }
    }

    private var isValidRound: Bool {
        BeloteScoring.isRoundTotalValid(teamAPoints: teamAPoints, teamBPoints: teamBPoints, hasBelote: false)
    }

    private var scoreInput: BeloteRoundScoreInput {
        BeloteRoundScoreInput(
            takerTeam: takerTeam,
            trickPointsTeamA: teamAPoints,
            trickPointsTeamB: teamBPoints,
            beloteTeam: hasBelote ? beloteTeam : nil,
            tookAllTricksTeam: isCapot ? capotTeam : nil
        )
    }

    private var previewResult: BeloteRoundScoreResult? {
        try? dependencies.roundScoringService.scoreRound(scoreInput)
    }

    private func clamped(_ value: Int, total: Int) -> Int {
        min(max(value, 0), total)
    }

    private func addRound() {
        do {
            let result = try dependencies.roundScoringService.scoreRound(scoreInput)
            onCreate(
                BeloteRound(
                    trickPointsTeamA: teamAPoints,
                    trickPointsTeamB: teamBPoints,
                    teamAPoints: result.teamAPoints,
                    teamBPoints: result.teamBPoints,
                    beloteTeam: hasBelote ? beloteTeam : nil,
                    tookAllTricksTeam: isCapot ? capotTeam : nil,
                    dealerSeat: match.nextDealerSeat,
                    takerTeam: takerTeam,
                    trumpSuit: trumpSuit,
                    outcome: result.outcome,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                    match: match
                )
            )
            dismiss()
        } catch {
            scoringError = error.localizedDescription
        }
    }

    private func syncCapotPointsIfNeeded() {
        guard isCapot else {
            return
        }

        switch capotTeam {
        case .teamA:
            teamAPoints = BeloteScoring.baseRoundPoints
            teamBPoints = 0
        case .teamB:
            teamAPoints = 0
            teamBPoints = BeloteScoring.baseRoundPoints
        }
    }

    private func refreshScoringError() {
        do {
            _ = try dependencies.roundScoringService.scoreRound(scoreInput)
            scoringError = nil
        } catch {
            scoringError = error.localizedDescription
        }
    }
}
