import SwiftUI

/// 设置页：账号与安全 / 通知 / 通用 / 关于 / 退出登录
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var notifyMessage = true
    @State private var notifyMatch = true
    @State private var notifyActivity = false
    @State private var darkMode = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    accountSection
                    notificationSection
                    generalSection
                    aboutSection
                    logoutButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(Color.banbanBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            darkMode = appState.preferredColorScheme == .dark
        }
    }

    // MARK: - 头部

    private var header: some View {
        ZStack {
            Text("设置")
                .font(BanBanFont.h2)
                .foregroundStyle(Color.banbanForeground)
            HStack {
                CircleIconButton(icon: "chevron.left") { dismiss() }
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - 账号与安全

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "账号与安全")
            SectionCard {
                VStack(spacing: 0) {
                    SettingRow(
                        title: "修改手机号",
                        value: "138****1234"
                    ) {}
                    SettingRow(
                        title: "修改密码",
                        showsChevron: true
                    ) {}
                    NavigationLink {
                        VerifyIDView(mode: .settings)
                    } label: {
                        SettingRow(
                            title: "实名认证状态",
                            value: "未认证"
                        ) {}
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 通知

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "通知")
            SectionCard {
                VStack(spacing: 0) {
                    ToggleRow(title: "接收新消息", isOn: $notifyMessage)
                    ToggleRow(title: "接收匹配提醒", isOn: $notifyMatch)
                    ToggleRow(title: "接收活动通知", isOn: $notifyActivity)
                }
            }
        }
    }

    // MARK: - 通用

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "通用")
            SectionCard {
                VStack(spacing: 0) {
                    ToggleRow(title: "深色模式", isOn: $darkMode)
                        .onChange(of: darkMode) { newValue in
                            appState.preferredColorScheme = newValue ? .dark : .light
                        }
                    SettingRow(
                        title: "清除缓存",
                        value: "12.5 MB"
                    ) {}
                }
            }
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "关于")
            SectionCard {
                VStack(spacing: 0) {
                    SettingRow(title: "关于伴伴") {}
                    SettingRow(title: "用户协议") {}
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        SettingRow(title: "隐私政策") {}
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 退出登录

    private var logoutButton: some View {
        Button {
            appState.logout()
        } label: {
            Text("退出登录")
                .font(BanBanFont.bodyLarge.weight(.medium))
                .foregroundStyle(Color.banbanError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: BanBanRadius.large)
                        .fill(Color.banbanCard)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}
