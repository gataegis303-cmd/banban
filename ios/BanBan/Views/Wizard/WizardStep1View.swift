import SwiftUI

/// 向导步骤 1：基础信息
struct WizardStep1View: View {
    @Binding var draft: ProfileDraft
    @State private var birthday: Date

    init(draft: Binding<ProfileDraft>) {
        _draft = draft
        let fallback = Calendar.current.date(from: DateComponents(year: 1994, month: 1, day: 1)) ?? Date()
        _birthday = State(initialValue: draft.wrappedValue.birthday ?? fallback)
    }

    /// 成年日期上限：18 岁前的今天
    private var adultDate: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            WizardStepTitle(title: "基础信息", subtitle: "先让大家认识一下你")

            WizardFieldGroup(title: "昵称") {
                InputField(icon: "person", placeholder: "请输入昵称", text: $draft.nickname, maxLength: 12)
            }

            WizardFieldGroup(title: "性别") {
                SegmentGroup(options: Gender.allCases, selection: $draft.gender)
            }

            WizardFieldGroup(title: "出生日期") {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.banbanMutedForeground)
                        .frame(width: 20)
                    DatePicker("", selection: $birthday, in: ...adultDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(Color.banbanPrimary)
                }
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(Color.banbanInput.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: BanBanRadius.medium)
                        .strokeBorder(Color.banbanBorder, lineWidth: 1)
                )
                .onAppear {
                    // 初始值回写 draft：UI 显示与 draft 恒一致（含编辑模式回填）
                    if draft.birthday == nil { draft.birthday = birthday }
                }
                .onChange(of: birthday) { newValue in
                    draft.birthday = newValue
                }
            }

            WizardFieldGroup(title: "所在城市") {
                InputField(icon: "mappin", placeholder: "请选择所在城市", text: $draft.city, maxLength: 20)
            }

            WizardFieldGroup(title: "职业") {
                InputField(icon: "briefcase", placeholder: "请输入职业", text: $draft.occupation, maxLength: 20)
            }

            WizardFieldGroup(title: "婚姻状态") {
                SegmentGroup(options: MarriageStatus.allCases, selection: $draft.marriage)
            }

            WizardFieldGroup(title: "子女情况") {
                SegmentGroup(options: ChildrenStatus.allCases, selection: $draft.children)
            }
        }
    }
}
