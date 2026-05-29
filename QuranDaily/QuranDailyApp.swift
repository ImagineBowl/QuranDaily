//
//  QuranDailyApp.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import SwiftUI

@main
struct QuranDailyApp: App {
    private let container = AppContainer.shared

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
