import SwiftUI

/// 主界面：首页 / 消息 / 广场 / 我的
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("首页", systemImage: "house") }
                .tag(0)

            MessagesView()
                .tabItem { Label("消息", systemImage: "message") }
                .badge(appState.totalUnread)
                .tag(1)

            SquarePlaceholderView()
                .tabItem { Label("广场", systemImage: "square.grid.2x2") }
                .tag(2)

            MyProfileView()
                .tabItem { Label("我的", systemImage: "person") }
                .tag(3)
        }
        .tint(Color.banbanPrimary)
    }
}

/// 广场占位（功能筹备中）
private struct SquarePlaceholderView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("广场")
                    .font(BanBanFont.h2)
                    .foregroundStyle(Color.banbanForeground)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Spacer()
            EmptyStateView(icon: "square.grid.2x2", title: "广场正在筹备中", subtitle: "更多搭伴活动即将上线，敬请期待")
            Spacer()
        }
        .background(Color.banbanBackground.ignoresSafeArea())
    }
}
