import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            switch appState.phase {
            case .onboarding:
                OnboardingFlowView()
            case .registration:
                WizardFlowView(mode: .registration)
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.phase)
    }
}
