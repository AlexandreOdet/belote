//
//  BeloteApp.swift
//  Belote
//
//  Created by Alexandre Odet on 30/07/2026.
//

import SwiftUI
import SwiftData

@main
struct BeloteApp: App {
    var sharedModelContainer: ModelContainer = Self.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.beloteDependencies, .live)
        }
        .modelContainer(sharedModelContainer)
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            BeloteMatch.self,
            BeloteRound.self,
        ])
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
