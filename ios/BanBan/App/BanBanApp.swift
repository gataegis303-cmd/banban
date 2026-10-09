//
//  BanBanApp.swift
//  BanBan
//
//  应用入口：持有全局 AppState，注入主题色与深浅色偏好
//

import SwiftUI

@main
struct BanBanApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.preferredColorScheme.colorScheme)
                .tint(.banbanPrimary)
        }
    }
}
