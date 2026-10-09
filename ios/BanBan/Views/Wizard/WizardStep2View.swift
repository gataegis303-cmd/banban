import SwiftUI

/// 向导步骤 2：生活方式
struct WizardStep2View: View {
    @Binding var draft: ProfileDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            WizardStepTitle(title: "生活方式", subtitle: "了解你的日常习惯，找到更契合的搭伴")

            WizardFieldGroup(title: "是否吸烟") {
                SegmentGroup(options: YesNoSometimes.allCases, selection: $draft.smoking)
            }

            WizardFieldGroup(title: "是否饮酒") {
                SegmentGroup(options: YesNoSometimes.allCases, selection: $draft.drinking)
            }

            WizardFieldGroup(title: "睡眠习惯") {
                SegmentGroup(options: SleepHabit.allCases, selection: $draft.sleep)
            }

            WizardFieldGroup(title: "宠物偏好") {
                MultiChipRow(options: TagOptions.pets, selection: $draft.pets)
            }
        }
    }
}
