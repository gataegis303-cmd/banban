import SwiftUI

/// 向导模式：注册引导 / 编辑资料
enum WizardMode {
    case registration
    case edit
}

// MARK: - 向导内部小组件（各步骤共用）

/// 向导字段标题（原型 label 为 foreground 色）
struct WizardFieldGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BanBanFont.label)
                .foregroundStyle(Color.banbanForeground)
            content
        }
    }
}

/// 步骤大标题 + 副文案
struct WizardStepTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BanBanFont.h1)
                .foregroundStyle(Color.banbanForeground)
            Text(subtitle)
                .font(BanBanFont.body)
                .foregroundStyle(Color.banbanMutedForeground)
        }
    }
}

/// 向导底栏胶囊按钮
struct WizardCapsuleButton: View {
    enum Style { case primary, secondary }

    let title: String
    var icon: String? = nil
    var style: Style = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
            }
            .font(BanBanFont.bodyLarge.weight(.medium))
            .foregroundStyle(style == .primary ? Color.banbanPrimaryForeground : Color.banbanForeground)
            .padding(.horizontal, style == .primary ? 26 : 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: BanBanRadius.full)
                    .fill(style == .primary ? Color.banbanPrimary : Color.banbanCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BanBanRadius.full)
                    .strokeBorder(style == .primary ? Color.clear : Color.banbanBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 向导主容器

struct WizardFlowView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let mode: WizardMode

    @State private var step = 1

    var body: some View {
        VStack(spacing: 0) {
            WizardProgressHeader(
                step: step,
                showsClose: mode == .edit,
                onClose: { dismiss() }
            )

            ScrollView(showsIndicators: false) {
                Group {
                    switch step {
                    case 1: WizardStep1View(draft: $appState.draft)
                    case 2: WizardStep2View(draft: $appState.draft)
                    case 3: WizardStep3View(draft: $appState.draft)
                    default: WizardStep4View(draft: $appState.draft)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
                .id(step)
            }

            bottomBar
        }
        .background(Color.banbanBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: 底栏（步骤点 + 上一步 / 下一步 / 完成）

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.banbanBorder.opacity(0.6))
                .frame(height: 0.5)

            HStack {
                HStack(spacing: 6) {
                    ForEach(1...4, id: \.self) { index in
                        Circle()
                            .fill(index <= step ? Color.banbanPrimary : Color.banbanInput.opacity(0.6))
                            .frame(width: 8, height: 8)
                    }
                }
                Spacer()
                HStack(spacing: 12) {
                    if step > 1 {
                        WizardCapsuleButton(title: "上一步", style: .secondary) {
                            withAnimation(.easeInOut(duration: 0.2)) { step -= 1 }
                        }
                    }
                    if step < 4 {
                        WizardCapsuleButton(title: "下一步") {
                            withAnimation(.easeInOut(duration: 0.2)) { step += 1 }
                        }
                    } else {
                        WizardCapsuleButton(title: "完成", icon: "check") {
                            finish()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.banbanCard)
        .banbanShadow(2)
    }

    private func finish() {
        switch mode {
        case .registration:
            appState.completeRegistration()
        case .edit:
            appState.saveProfileEdits()
            dismiss()
        }
    }
}
