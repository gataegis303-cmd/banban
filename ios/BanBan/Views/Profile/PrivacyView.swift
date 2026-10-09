import SwiftUI

/// 隐私设置：4 项开关 + 提示条
struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var certifiedOnly = false
    @State private var hideDistance = false
    @State private var hideOnline = false
    @State private var blockPhoneSearch = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionCard {
                        VStack(spacing: 0) {
                            ToggleRow(
                                title: "资料仅对认证用户可见",
                                subtitle: "开启后未认证用户无法查看你的资料",
                                isOn: $certifiedOnly
                            )
                            ToggleRow(
                                title: "隐藏精确距离",
                                subtitle: "仅展示大致距离范围",
                                isOn: $hideDistance
                            )
                            ToggleRow(
                                title: "隐藏在线状态",
                                subtitle: "其他人将无法看到你是否在线",
                                isOn: $hideOnline
                            )
                            ToggleRow(
                                title: "不允许通过手机号找到我",
                                isOn: $blockPhoneSearch
                            )
                        }
                    }

                    InfoBanner(
                        text: "真实姓名、手机号、精确住址默认不会展示给其他用户",
                        style: .info
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(Color.banbanBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - 头部

    private var header: some View {
        ZStack {
            Text("隐私设置")
                .font(BanBanFont.h2)
                .foregroundStyle(Color.banbanForeground)
            HStack {
                CircleIconButton(icon: "chevron.left", label: "返回") { dismiss() }
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
