//
//  BeloteDependencies.swift
//  Belote
//
//  Created by Alexandre Odet on 05/08/2026.
//

import SwiftUI

struct BeloteDependencies {
    var roundScoringService: any BeloteRoundScoringService
    var matchSharingService: any BeloteMatchSharingService
    var cardValueService: any BeloteCardValueService
    var trickResolvingService: any BeloteTrickResolvingService
    var dealService: any BeloteDealService
    var roundPlayService: any BeloteRoundPlayService
    var playableCardService: any BelotePlayableCardService
    var roundPlaySessionPersistenceService: any BeloteRoundPlaySessionPersistenceService
    var matchSyncService: any BeloteMatchSyncService
    var joinLinkService: any BeloteJoinLinkService
    var matchStateService: any BeloteMatchStateService

    static let live = BeloteDependencies(
        roundScoringService: StandardBeloteRoundScoringService(),
        matchSharingService: StandardBeloteMatchSharingService(),
        cardValueService: StandardBeloteCardValueService(),
        trickResolvingService: StandardBeloteTrickResolvingService(),
        dealService: StandardBeloteDealService(),
        roundPlayService: StandardBeloteRoundPlayService(),
        playableCardService: StandardBelotePlayableCardService(),
        roundPlaySessionPersistenceService: StandardBeloteRoundPlaySessionPersistenceService(),
        matchSyncService: CloudKitBeloteMatchSyncService(),
        joinLinkService: StandardBeloteJoinLinkService(),
        matchStateService: StandardBeloteMatchStateService()
    )
}

private struct BeloteDependenciesKey: EnvironmentKey {
    static let defaultValue = BeloteDependencies.live
}

extension EnvironmentValues {
    var beloteDependencies: BeloteDependencies {
        get { self[BeloteDependenciesKey.self] }
        set { self[BeloteDependenciesKey.self] = newValue }
    }
}
