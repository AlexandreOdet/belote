//
//  JoinMatchView.swift
//  Belote
//
//  Created by Alexandre Odet on 20/08/2026.
//

import SwiftUI

struct JoinMatchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.beloteDependencies) private var dependencies
    @State private var viewModel = MatchJoinViewModel()
    @State private var isShowingScanner = false
    let initialURL: URL?
    let onImport: (BeloteMatch) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Code") {
                    TextField("1234-5678", text: $viewModel.inviteCode)
                    Button {
                        importMatch()
                    } label: {
                        Label("Importer la partie", systemImage: "icloud.and.arrow.down")
                    }
                    .disabled(viewModel.isImporting || viewModel.inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("QR Code") {
#if os(iOS)
                    Button {
                        isShowingScanner = true
                    } label: {
                        Label("Scanner un QR Code", systemImage: "qrcode.viewfinder")
                    }
#else
                    ContentUnavailableView("Scan indisponible sur Mac", systemImage: "qrcode.viewfinder", description: Text("Entre le code de partage manuellement."))
#endif
                }

                if let statusMessage = viewModel.statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Rejoindre")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                applyInitialURLIfNeeded()
            }
#if os(iOS)
            .sheet(isPresented: $isShowingScanner) {
                QRCodeScannerView { payload in
                    handleScannedPayload(payload)
                }
            }
#endif
        }
    }

    private func applyInitialURLIfNeeded() {
        guard let initialURL else {
            return
        }

        _ = viewModel.apply(url: initialURL, joinLinkService: dependencies.joinLinkService)
    }

    private func handleScannedPayload(_ payload: String) {
        if let url = URL(string: payload), viewModel.apply(url: url, joinLinkService: dependencies.joinLinkService) {
            isShowingScanner = false
            importMatch()
            return
        }

        viewModel.inviteCode = payload.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        isShowingScanner = false
    }

    private func importMatch() {
        var nextViewModel = viewModel
        Task {
            let match = await nextViewModel.importMatch(
                matchSyncService: dependencies.matchSyncService,
                sharingService: dependencies.matchSharingService
            )
            viewModel = nextViewModel

            if let match {
                onImport(match)
                dismiss()
            }
        }
    }
}
