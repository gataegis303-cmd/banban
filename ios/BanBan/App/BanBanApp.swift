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
