//
//  PermissionsView.swift
//  BanBan · 权限开启（认证流终点）
//
//  对应 pages/permissions.html：3 开关卡（默认全开）+ 进入伴伴
//

import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var location = true
    @State private var notification = true
    @State private var photos = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CircleIconButton(icon: "chevron.left") { dismiss() }

            VStack(alignment: .leading, spacing: 8) {
                Text("开启以下权限，体验更完整")
                    .font(BanBanFont.h1)
                    .foregroundStyle(Color.banbanForeground)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                permissionCard(icon: "mappin", title: "位置权限", subtitle: "推荐同城搭伴对象", isOn: $location)
                permissionCard(icon: "bell.fill", title: "通知权限", subtitle: "不错过匹配与消息", isOn: $notification)
                permissionCard(icon: "photo.fill", title: "相册权限", subtitle: "上传真实生活照片", isOn: $photos)
            }

            Spacer()

            PrimaryButton(title: "进入伴伴") {
                appState.completeOnboarding()
            }

            Button {
                appState.completeOnboarding()
            } label: {
                Text("稍后在设置中开启")
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanMutedForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .background(Color.banbanBackground)
        .navigationBarBackButtonHidden(true)
    }

    private func permissionCard(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Color.banbanPrimary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.banbanPrimary.opacity(0.12)))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(BanBanFont.bodyLarge.weight(.semibold))
                    .foregroundStyle(Color.banbanForeground)
                Text(subtitle)
                    .font(BanBanFont.caption)
                    .foregroundStyle(Color.banbanMutedForeground)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.banbanPrimary)
        }
        .padding(14)
        .background(Color.banbanCard)
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.large))
        .banbanShadow(1)
    }
}
