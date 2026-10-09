import SwiftUI

/// 安全中心：账号状态 + 举报记录 / 黑名单 / 紧急联系人 / 帮助与反馈
struct SafetyView: View {
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    statusCard
                    actionList
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color.banbanBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - 头部

    private var header: some View {
        ZStack {
            Text("安全中心")
                .font(BanBanFont.h2)
                .foregroundStyle(Color.banbanCardForeground)
            HStack {
                CircleIconButton(icon: "chevron.left") { onBack() }
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.banbanCard)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.banbanBorder.opacity(0.5))
                .frame(height: 0.5)
        }
    }

    // MARK: - 状态卡

    private var statusCard: some View {
        SectionCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.banbanSuccessSubtle)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.banbanSuccess)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text("账号状态正常")
                        .font(BanBanFont.bodyLarge.weight(.semibold))
                        .foregroundStyle(Color.banbanCardForeground)
                    Text("实名认证已通过")
                        .font(BanBanFont.caption)
                        .foregroundStyle(Color.banbanMutedForeground)
                }
                Spacer()
            }
        }
    }

    // MARK: - 功能列表

    private var actionList: some View {
        SectionCard {
            VStack(spacing: 0) {
                actionRow(icon: "flag", title: "举报记录", subtitle: "查看我提交的举报") {}
                actionRow(icon: "ban", title: "黑名单", subtitle: "管理已屏蔽的用户") {}
                NavigationLink {
                    SettingsView()
                } label: {
                    actionRow(icon: "phone.fill", title: "紧急联系人", subtitle: "设置应急联络方式") {}
                }
                .buttonStyle(.plain)
                actionRow(icon: "questionmark.circle", title: "帮助与反馈", subtitle: "获取安全相关帮助", showsBorder: false) {}
            }
        }
    }

    private func actionRow(icon: String, title: String, subtitle: String, showsBorder: Bool = true, action: @escaping () -> Void) -> some View {
        SettingRow(
            icon: icon,
            title: title,
            subtitle: subtitle,
            showsChevron: true,
            action: action
        )
        .overlay(alignment: .bottom) {
            if showsBorder {
                Rectangle()
                    .fill(Color.banbanBorder.opacity(0.6))
                    .frame(height: 0.5)
            }
        }
    }
}
