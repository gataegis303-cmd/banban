//
//  BanBanApp.swift
//  BanBan
//
//  应用入口：持有全局 AppState，注入主题色与深浅色偏好；
//  AppDelegate 承接 APNs device token 系统回调（转交 NotificationManager）
//

import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.handleDidRegister(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // 真机未配 Push Notifications capability 时走到这里：推送为增强能力，静默降级
    }
}

@main
struct BanBanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
