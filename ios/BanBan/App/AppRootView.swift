//
//  AppRootView.swift
//  BanBan
//
//  根视图：按 AppState.phase 切换引导流 / 注册向导 / 主 Tab
//

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
