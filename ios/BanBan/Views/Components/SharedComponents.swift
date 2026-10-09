//
//  SharedComponents.swift
//  BanBan · 共享组件库
//
//  对应 dev-handoff/02-component-inventory.md：
//  FlowLayout / ChipButton / EnumChipRow / MultiChipRow / SegmentGroup /
//  PrimaryButton / SecondaryButton / CircleIconButton / AvatarView /
//  VerifiedBadge / InfoBanner / InputField / SectionCard / StepperRow /
//  TagEntryField / WizardProgressHeader / EmptyStateView / ToggleRow 等
//

import SwiftUI

// MARK: - 流式布局（iOS 16 Layout 协议）

/// 芯片流式换行布局
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let width = maxWidth.isFinite ? maxWidth : x
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - 芯片按钮

/// 胶囊芯片：选中 = primary 12% 底 + primary 边 + primary 字
struct ChipButton: View {
    let title: String
    let isSelected: Bool
    var font: Font = BanBanFont.body
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundStyle(isSelected ? Color.banbanPrimary : Color.banbanForeground)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.banbanPrimary.opacity(0.12) : Color.banbanCard)
                .overlay(
                    Capsule().strokeBorder(isSelected ? Color.banbanPrimary : Color.banbanBorder, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// 单选枚举芯片行（再次点击取消选择）
struct EnumChipRow<T: OptionEnum & Equatable>: View {
    let options: [T]
    @Binding var selection: T?

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options) { option in
                ChipButton(title: option.rawValue, isSelected: selection == option) {
                    selection = selection == option ? nil : option
                }
            }
        }
    }
}

/// 单选字符串芯片行（再次点击取消选择）
struct StringChipRow: View {
    let options: [String]
    @Binding var selection: String?

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                ChipButton(title: option, isSelected: selection == option) {
                    selection = selection == option ? nil : option
                }
            }
        }
    }
}

/// 多选字符串芯片行
struct MultiChipRow: View {
    let options: [String]
    @Binding var selection: Set<String>

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                ChipButton(title: option, isSelected: selection.contains(option)) {
                    if selection.contains(option) {
                        selection.remove(option)
                    } else {
                        selection.insert(option)
                    }
                }
            }
        }
    }
}

// MARK: - 分段单选（向导 / 筛选）

/// 分段单选组：容器 input 底 p-1 圆角 8 + 边框，选中项 primary 底
/// 选项 ≤3 个时平铺一行，>3 个时每行 3 列
struct SegmentGroup<T: OptionEnum & Equatable>: View {
    let options: [T]
    @Binding var selection: T?

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: min(options.count, 3))
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(options) { option in
                let isSelected = selection == option
                Button {
                    selection = option
                } label: {
                    Text(option.rawValue)
                        .font(BanBanFont.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? Color.banbanPrimaryForeground : Color.banbanMutedForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: BanBanRadius.small)
                                .fill(isSelected ? Color.banbanPrimary : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.banbanInput.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: BanBanRadius.medium)
                .strokeBorder(Color.banbanBorder, lineWidth: 1)
        )
    }
}

// MARK: - 按钮

/// 主按钮标签（供 Button 与 NavigationLink 复用）
struct PrimaryButtonLabel: View {
    let title: String
    var icon: String? = nil
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
            }
            Text(title)
        }
        .font(BanBanFont.bodyLarge.weight(.semibold))
        .foregroundStyle(Color.banbanPrimaryForeground)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.banbanPrimary)
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
        .opacity(isEnabled ? 1 : 0.5)
    }
}

/// 主按钮（高 50、圆角 8、禁用时 opacity 0.5）
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PrimaryButtonLabel(title: title, icon: icon)
        }
        .buttonStyle(.plain)
    }
}

/// 次按钮（描边）
struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
            }
            .font(BanBanFont.bodyLarge.weight(.semibold))
            .foregroundStyle(Color.banbanForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.banbanCard)
            .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: BanBanRadius.medium)
                    .strokeBorder(Color.banbanBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// 圆形图标按钮（顶栏返回 / 筛选 / 铃铛等）
struct CircleIconButton: View {
    let icon: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.banbanForeground)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 头像 / 徽章

/// 头像：网络图加载失败时回退首字占位
struct AvatarView: View {
    let url: URL?
    var size: CGFloat
    var initial: String

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                ZStack {
                    Rectangle().fill(Color.banbanMuted)
                    Text(initial)
                        .font(.system(size: size * 0.4, weight: .medium))
                        .foregroundStyle(Color.banbanMutedForeground)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// 实名认证徽章：checkmark.shield，可带「已认证」文字
struct VerifiedBadge: View {
    var showText: Bool = false

    var body: some View {
        Group {
            if showText {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("已认证")
                        .font(BanBanFont.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.banbanSuccess)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.banbanSuccessSubtle)
                .clipShape(Capsule())
            } else {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.banbanSuccess)
            }
        }
    }
}

// MARK: - 横幅 / 空状态

enum InfoBannerStyle {
    case info
    case warning
}

/// 提示横幅（info / warning 两态）
struct InfoBanner: View {
    let text: String
    var style: InfoBannerStyle = .info

    private var tint: Color {
        style == .info ? Color.banbanInfo : Color.banbanWarning
    }

    private var background: Color {
        style == .info ? Color.banbanInfoSubtle : Color.banbanWarningSubtle
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: style == .info ? "info.circle" : "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint)
            Text(text)
                .font(BanBanFont.caption)
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
    }
}

/// 空状态视图（iOS 16 无 ContentUnavailableView 的替代）
struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.banbanMutedForeground)
            Text(title)
                .font(BanBanFont.bodyLarge.weight(.semibold))
                .foregroundStyle(Color.banbanForeground)
            if let subtitle {
                Text(subtitle)
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanMutedForeground)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - 输入框

/// 左图标输入框（r8 边框）
struct InputField: View {
    var icon: String? = nil
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    /// 最大输入长度（nil 不限），超出即时截断
    var maxLength: Int? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.banbanMutedForeground)
                    .frame(width: 20)
            }
            TextField(placeholder, text: $text)
                .font(BanBanFont.bodyLarge)
                .foregroundStyle(Color.banbanForeground)
                .keyboardType(keyboardType)
                .onChange(of: text) { newValue in
                    if let maxLength, newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(Color.banbanInput.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: BanBanRadius.medium)
                .strokeBorder(Color.banbanBorder, lineWidth: 1)
        )
    }
}

// MARK: - 卡片 / 分组

/// 内容卡片：card 底 r12 p16 + shadow-1
struct SectionCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.banbanCard)
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.large))
        .banbanShadow(1)
    }
}

/// 卡片标题（左图标 + 标题）
struct SectionHeader: View {
    var icon: String? = nil
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.banbanPrimary)
            }
            Text(title)
                .font(BanBanFont.bodyLarge.weight(.semibold))
                .foregroundStyle(Color.banbanForeground)
        }
    }
}

/// 设置分组小标题
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(BanBanFont.caption)
            .foregroundStyle(Color.banbanMutedForeground)
            .padding(.leading, 4)
    }
}

/// 信息行：label 左、value 右（资料页）
struct InfoRow: View {
    let label: String
    let value: String
    var showsBorder: Bool = true

    var body: some View {
        HStack {
            Text(label)
                .font(BanBanFont.body)
                .foregroundStyle(Color.banbanMutedForeground)
            Spacer()
            Text(value)
                .font(BanBanFont.body)
                .foregroundStyle(Color.banbanForeground)
                .multilineTextAlignment(.trailing)
        }
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            if showsBorder {
                Rectangle()
                    .fill(Color.banbanBorder.opacity(0.6))
                    .frame(height: 0.5)
            }
        }
    }
}

/// 设置行：图标 + 标题/副标题 + 右侧值 + 箭头
struct SettingRow: View {
    var icon: String? = nil
    var iconColor: Color = .banbanPrimary
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var valueColor: Color = .banbanMutedForeground
    var showsChevron: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    RoundedRectangle(cornerRadius: BanBanRadius.small)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(iconColor)
                        )
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BanBanFont.body)
                        .foregroundStyle(Color.banbanForeground)
                    if let subtitle {
                        Text(subtitle)
                            .font(BanBanFont.caption)
                            .foregroundStyle(Color.banbanMutedForeground)
                    }
                }
                Spacer()
                if let value {
                    Text(value)
                        .font(BanBanFont.body)
                        .foregroundStyle(valueColor)
                }
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.banbanMutedForeground)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 开关行：标题 + 副标题 + Toggle
struct ToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanForeground)
                if let subtitle {
                    Text(subtitle)
                        .font(BanBanFont.caption)
                        .foregroundStyle(Color.banbanMutedForeground)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.banbanPrimary)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - 步进器

/// 数量步进行：label + 减/加按钮 + 数值
struct StepperRow: View {
    let label: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...9

    var body: some View {
        HStack {
            Text(label)
                .font(BanBanFont.body)
                .foregroundStyle(Color.banbanForeground)
            Spacer()
            Button {
                if value > range.lowerBound { value -= 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(value > range.lowerBound ? Color.banbanForeground : Color.banbanMutedForeground)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.banbanInput.opacity(0.5)))
            }
            .buttonStyle(.plain)
            Text("\(value)")
                .font(BanBanFont.bodyLarge.weight(.semibold))
                .foregroundStyle(Color.banbanForeground)
                .frame(minWidth: 24)
            Button {
                if value < range.upperBound { value += 1 }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(value < range.upperBound ? Color.banbanForeground : Color.banbanMutedForeground)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.banbanPrimary.opacity(0.15)))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 标签录入（向导 4 其他标签）

/// 自定义标签录入：trim / 限 12 字 / 去重 / 可删
struct TagEntryField: View {
    @Binding var tags: [String]
    @State private var input = ""

    private func addTag() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed.count <= ProfileDraft.otherTagLimit else { return }
        guard !tags.contains(trimmed) else { input = ""; return }
        tags.append(trimmed)
        input = ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("输入自定义标签（12 字以内）", text: $input)
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanForeground)
                    .submitLabel(.done)
                    .onChange(of: input) { newValue in
                        // 输入时即时截断，避免 addTag 因超长静默失败
                        if newValue.count > ProfileDraft.otherTagLimit {
                            input = String(newValue.prefix(ProfileDraft.otherTagLimit))
                        }
                    }
                    .onSubmit(addTag)
                Button(action: addTag) {
                    Text("添加")
                        .font(BanBanFont.label)
                        .foregroundStyle(Color.banbanPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Color.banbanInput.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: BanBanRadius.medium)
                    .strokeBorder(Color.banbanBorder, lineWidth: 1)
            )

            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 6) {
                            Text(tag)
                                .font(BanBanFont.caption)
                                .foregroundStyle(Color.banbanForeground)
                            Button {
                                tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.banbanMutedForeground)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.banbanPrimary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

// MARK: - 向导进度头

/// 向导进度头：步骤 X/4 + 百分比 + 进度条；编辑态带关闭按钮
struct WizardProgressHeader: View {
    let step: Int
    var total: Int = 4
    var showsClose: Bool = false
    var onClose: () -> Void = {}

    private var progress: Double { Double(step) / Double(total) }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                if showsClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.banbanForeground)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.banbanInput.opacity(0.4)))
                    }
                    .buttonStyle(.plain)
                }
                Text("步骤 \(step)/\(total)")
                    .font(BanBanFont.label)
                    .foregroundStyle(Color.banbanForeground)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(BanBanFont.label)
                    .foregroundStyle(Color.banbanPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.banbanInput.opacity(0.5))
                    Capsule()
                        .fill(Color.banbanPrimary)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
            .animation(.easeInOut(duration: 0.25), value: step)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

// MARK: - 表单字段行

/// 向导字段容器：小标题 + 内容
struct FieldGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(BanBanFont.label)
                .foregroundStyle(Color.banbanMutedForeground)
            content
        }
    }
}
