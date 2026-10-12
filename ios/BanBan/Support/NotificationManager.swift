//
//  NotificationManager.swift
//  BanBan
//
//  APNs 推送注册：授权请求 → registerForRemoteNotifications →
//  系统回调（AppDelegate）转交 device token → 经 onToken 交 AppState 上报服务端。
//  真机需 Xcode 勾选 Push Notifications capability；模拟器 Xcode 11.4+ 可收 sim 推送。
//

import UIKit
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    /// device token hex 就绪回调（AppState 注入后上报服务端并留档供登出注销）
    var onToken: ((String) -> Void)?

    /// 授权请求 + 注册远程推送（幂等，可重复调用；授权拒绝不影响注册静默推送）
    func register() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// AppDelegate didRegisterForRemoteNotifications 转发入口：Data → hex 上报
    func handleDidRegister(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        onToken?(hex)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// 前台也展示横幅（在线会话 WS 已实时显示，其余会话推送补横幅与角标）
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }
}
