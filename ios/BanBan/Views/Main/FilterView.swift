import SwiftUI

/// 筛选页（sheet）：城市 / 年龄区间 / 搭伴条件
struct FilterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var draft = FilterState()

    var body: some View {
        ZStack {
            Color.banbanBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        citySection
                        ageSection

                        FieldGroup(title: "搭伴方向") {
                            EnumChipRow(options: MatchDirection.allCases, selection: $draft.direction)
                        }
                        FieldGroup(title: "可接受伴侣状态") {
                            EnumChipRow(options: PartnerStatus.allCases, selection: $draft.partnerStatus)
                        }
                        FieldGroup(title: "搭伴对象") {
                            EnumChipRow(options: SeekingGender.allCases, selection: $draft.seeking)
                        }
                        FieldGroup(title: "居住模式") {
                            EnumChipRow(options: LivingMode.allCases, selection: $draft.livingMode)
                        }
                        FieldGroup(title: "与父母关系") {
                            EnumChipRow(options: ParentRelation.allCases, selection: $draft.parentRelation)
                        }
                        FieldGroup(title: "试用期财务管理") {
                            EnumChipRow(options: FinanceMode.allCases, selection: $draft.financeTrial)
                        }
                        FieldGroup(title: "正式关系后财务管理") {
                            EnumChipRow(options: FormalFinanceMode.allCases, selection: $draft.financeFormal)
                        }
                        FieldGroup(title: "是否生育") {
                            EnumChipRow(options: ChildIntent.allCases, selection: $draft.childIntent)
                        }
                        FieldGroup(title: "宠物偏好") {
                            MultiChipRow(options: TagOptions.pets, selection: $draft.pets)
                        }
                        FieldGroup(title: "我不能接受") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("不能接受（排除）：匹配时排除含这些特质的用户")
                                    .font(BanBanFont.caption)
                                    .foregroundStyle(Color.banbanMutedForeground)
                                MultiChipRow(
                                    options: TagOptions.negativeNoAccept + TagOptions.neutralNoAccept,
                                    selection: $draft.noAccept
                                )
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 12)
                }

                footerBar
            }
        }
        .onAppear {
            draft = appState.filter
        }
    }

    // MARK: 顶栏

    private var headerBar: some View {
        HStack {
            CircleIconButton(icon: "chevron.left") { dismiss() }
            Spacer()
            Text("筛选条件")
                .font(BanBanFont.h2)
                .foregroundStyle(Color.banbanForeground)
            Spacer()
            Button {
                draft = FilterState()
            } label: {
                Text("重置")
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: 城市

    private var citySection: some View {
        FieldGroup(title: "城市") {
            FlowLayout(spacing: 8) {
                ForEach(FilterState.cities, id: \.self) { city in
                    let isAll = city == "全部城市"
                    ChipButton(title: city, isSelected: isAll ? draft.city == nil : draft.city == city) {
                        draft.city = isAll ? nil : city
                    }
                }
            }
        }
    }

    // MARK: 年龄

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("年龄")
                    .font(BanBanFont.label)
                    .foregroundStyle(Color.banbanMutedForeground)
                Spacer()
                Text("\(draft.ageRange.lowerBound) - \(draft.ageRange.upperBound) 岁")
                    .font(BanBanFont.label)
                    .foregroundStyle(Color.banbanPrimary)
            }
            RangeSlider(range: $draft.ageRange, bounds: FilterState.ageBounds)
        }
    }

    // MARK: 底栏

    private var footerBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.banbanBorder.opacity(0.6))
                .frame(height: 0.5)
            PrimaryButton(title: "显示 \(MockData.filterResultCount(draft)) 位结果") {
                appState.filter = draft
                dismiss()
            }
            .padding(20)
        }
        .background(Color.banbanCard)
    }
}

// MARK: - 双滑块年龄区间

struct RangeSlider: View {
    @Binding var range: ClosedRange<Int>
    let bounds: ClosedRange<Int>

    var body: some View {
        GeometryReader { geo in
            let span = CGFloat(bounds.upperBound - bounds.lowerBound)
            let width = geo.size.width
            let thumbSize: CGFloat = 22
            let lowX = position(for: range.lowerBound, width: width)
            let highX = position(for: range.upperBound, width: width)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.banbanInput.opacity(0.5))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.banbanPrimary)
                    .frame(width: max(0, highX - lowX), height: 4)
                    .offset(x: lowX)

                thumb(x: lowX - thumbSize / 2, size: thumbSize, gesture:
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let newLow = value(for: gesture.location.x, width: width, span: span)
                            range = min(newLow, range.upperBound - 1)...range.upperBound
                        }
                )
                thumb(x: highX - thumbSize / 2, size: thumbSize, gesture:
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let newHigh = value(for: gesture.location.x, width: width, span: span)
                            range = range.lowerBound...max(newHigh, range.lowerBound + 1)
                        }
                )
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 36)
    }

    private func position(for value: Int, width: CGFloat) -> CGFloat {
        let span = CGFloat(bounds.upperBound - bounds.lowerBound)
        return CGFloat(value - bounds.lowerBound) / span * width
    }

    private func value(for x: CGFloat, width: CGFloat, span: CGFloat) -> Int {
        let clamped = min(max(x, 0), width)
        return bounds.lowerBound + Int(round(clamped / width * span))
    }

    private func thumb<G: Gesture>(x: CGFloat, size: CGFloat, gesture: G) -> some View {
        Circle()
            .fill(Color.banbanCard)
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(Color.banbanPrimary, lineWidth: 2.5))
            .banbanShadow(1)
            .offset(x: x)
            .gesture(gesture)
    }
}
