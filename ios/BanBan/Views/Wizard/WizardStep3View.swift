import SwiftUI

/// 向导步骤 3：搭伴意向
struct WizardStep3View: View {
    @Binding var draft: ProfileDraft
    @State private var showsSeekingInfo = false

    /// 我不能接受：多选但保持原选择顺序
    private var noAcceptBinding: Binding<Set<String>> {
        Binding(
            get: { Set(draft.noAccept) },
            set: { newValue in
                var ordered = draft.noAccept.filter { newValue.contains($0) }
                for item in newValue where !ordered.contains(item) {
                    ordered.append(item)
                }
                draft.noAccept = ordered
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            WizardStepTitle(title: "搭伴意向", subtitle: "谈谈你对搭伴生活的期待与边界")

            WizardFieldGroup(title: "搭伴方向") {
                SegmentGroup(options: MatchDirection.allCases, selection: $draft.direction)
            }

            WizardFieldGroup(title: "可接受伴侣状态") {
                SegmentGroup(options: PartnerStatus.allCases, selection: $draft.partnerStatus)
            }

            WizardFieldGroup(title: "搭伴对象") {
                HStack(spacing: 10) {
                    SegmentGroup(options: SeekingGender.allCases, selection: $draft.seeking)
                    Button {
                        showsSeekingInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.banbanMutedForeground)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            WizardFieldGroup(title: "居住模式") {
                SegmentGroup(options: LivingMode.allCases, selection: $draft.livingMode)
            }

            WizardFieldGroup(title: "试用期财务管理") {
                SegmentGroup(options: FinanceMode.allCases, selection: $draft.financeTrial)
            }

            WizardFieldGroup(title: "正式关系后财务管理") {
                SegmentGroup(options: FormalFinanceMode.allCases, selection: $draft.financeFormal)
            }

            WizardFieldGroup(title: "是否生育") {
                SegmentGroup(options: ChildIntent.allCases, selection: $draft.childIntent)
            }

            WizardFieldGroup(title: "社交边界") {
                SegmentGroup(options: SocialBoundary.allCases, selection: $draft.socialBoundary)
            }

            WizardFieldGroup(title: "与父母关系") {
                SegmentGroup(options: ParentRelation.allCases, selection: $draft.parentRelation)
            }

            WizardFieldGroup(title: "我不能接受") {
                MultiChipRow(
                    options: TagOptions.negativeNoAccept + TagOptions.neutralNoAccept,
                    selection: noAcceptBinding
                )
            }

            WizardFieldGroup(title: "意向城市") {
                InputField(icon: "mappin", placeholder: "请输入意向城市", text: $draft.intendedCity, maxLength: 20)
            }
        }
        .sheet(isPresented: $showsSeekingInfo) {
            SeekingInfoSheet()
        }
    }
}

/// 搭伴对象说明弹层
private struct SeekingInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let cards: [(title: String, detail: String)] = [
        ("异性", "与异性结伴参加活动或互相陪伴，不含恋爱目的，双方需提前明确边界。"),
        ("同性", "与同性结伴出行或参加活动，兴趣与作息更容易一致，相处更放松。"),
        ("不限", "不限定搭伴对象的性别与关系形式，更看重兴趣匹配与相处舒适度。")
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.banbanBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("搭伴对象说明")
                    .font(BanBanFont.h2)
                    .foregroundStyle(Color.banbanForeground)
                Text("选择你期望的搭伴关系类型，双方默认按此理解彼此的边界")
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanMutedForeground)

                VStack(spacing: 10) {
                    ForEach(cards, id: \.title) { card in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(card.title)
                                .font(BanBanFont.bodyLarge.weight(.semibold))
                                .foregroundStyle(Color.banbanForeground)
                            Text(card.detail)
                                .font(BanBanFont.caption)
                                .foregroundStyle(Color.banbanMutedForeground)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.banbanCard)
                        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: BanBanRadius.large)
                                .strokeBorder(Color.banbanBorder, lineWidth: 1)
                        )
                    }
                }

                PrimaryButton(title: "我知道了") { dismiss() }
                Spacer(minLength: 0)
            }
            .padding(20)
        }
    }
}
