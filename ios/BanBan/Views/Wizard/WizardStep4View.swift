import SwiftUI

/// 向导步骤 4：我可提供 + 生活照片
struct WizardStep4View: View {
    @Binding var draft: ProfileDraft
    @State private var photos: [URL?] = Array(repeating: nil, count: 6)

    private var toolOptions: [String] { TagOptions.transportTools }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            WizardStepTitle(title: "我可提供", subtitle: "可多选，按分类勾选你能提供的资源与条件")

            // 出行工具
            WizardFieldGroup(title: "出行工具") {
                VStack(alignment: .leading, spacing: 8) {
                    FlowLayout(spacing: 8) {
                        transportChip("无", isSelected: draft.transportNone) {
                            draft.transportNone = true
                            draft.transportTools = []
                        }
                        ForEach(toolOptions, id: \.self) { tool in
                            transportChip(tool, isSelected: draft.transportTools.contains(tool)) {
                                toggleTool(tool)
                            }
                            if tool != "打车报销", draft.transportTools.contains(tool) {
                                TransportStepper(tool: tool, counts: $draft.transportCounts)
                            }
                        }
                    }
                    if draft.transportTools.contains("打车报销") {
                        taxiQuotaField
                    }
                }
            }

            // 居住情况
            WizardFieldGroup(title: "居住情况") {
                VStack(alignment: .leading, spacing: 8) {
                    StringChipRow(options: TagOptions.housingSituations, selection: $draft.housingSituation)
                    if draft.housingSituation != nil {
                        StepperRow(label: "可提供未使用房间数（可填 0）", value: $draft.spareRooms)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.banbanCard)
                            .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.large))
                            .overlay(
                                RoundedRectangle(cornerRadius: BanBanRadius.large)
                                    .strokeBorder(Color.banbanBorder, lineWidth: 1)
                            )
                    }
                }
            }

            WizardFieldGroup(title: "居住条件") {
                MultiChipRow(options: TagOptions.housingConditions, selection: $draft.housingConditions)
            }

            WizardFieldGroup(title: "资源") {
                MultiChipRow(options: TagOptions.resources, selection: $draft.resources)
            }

            WizardFieldGroup(title: "其他") {
                TagEntryField(tags: $draft.otherTags)
            }

            // 生活照片
            VStack(alignment: .leading, spacing: 12) {
                WizardStepTitle(title: "生活照片", subtitle: "上传 3-6 张真实生活照，展示你的日常状态")

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(photos.indices, id: \.self) { index in
                        photoSlot(index)
                    }
                }

                Text("照片需通过审核，请勿使用他人照片或过度修图")
                    .font(BanBanFont.caption)
                    .foregroundStyle(Color.banbanMutedForeground)
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            syncPhotosFromDraft()
        }
    }

    // MARK: 出行工具

    private func transportChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(BanBanFont.body)
                .foregroundStyle(isSelected ? Color.banbanPrimaryForeground : Color.banbanMutedForeground)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected ? Color.banbanPrimary : Color.banbanCard)
                )
                .overlay(
                    Capsule().strokeBorder(isSelected ? Color.clear : Color.banbanBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func toggleTool(_ tool: String) {
        if draft.transportTools.contains(tool) {
            draft.transportTools.remove(tool)
        } else {
            draft.transportTools.insert(tool)
            if draft.transportCounts[tool] == nil {
                draft.transportCounts[tool] = 1
            }
        }
        draft.transportNone = draft.transportTools.isEmpty
    }

    private var taxiQuotaField: some View {
        HStack(spacing: 8) {
            Text("月额度")
                .font(BanBanFont.caption)
                .foregroundStyle(Color.banbanMutedForeground)
            TextField("¥", text: $draft.taxiMonthlyQuota)
                .font(BanBanFont.body)
                .foregroundStyle(Color.banbanForeground)
                .keyboardType(.numberPad)
                .frame(width: 64)
            Text("元 / 月")
                .font(BanBanFont.caption)
                .foregroundStyle(Color.banbanMutedForeground)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.banbanCard)
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: BanBanRadius.large)
                .strokeBorder(Color.banbanBorder, lineWidth: 1)
        )
    }

    // MARK: 生活照片槽

    private func photoSlot(_ index: Int) -> some View {
        Button {
            if photos[index] == nil {
                photos[index] = URL(string: "https://picsum.photos/seed/banban-photo\(index + 1)/600/600")
            } else {
                photos[index] = nil
            }
            draft.photoCount = photos.compactMap { $0 }.count
        } label: {
            ZStack {
                if let url = photos[index] {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Rectangle().fill(Color.banbanInput.opacity(0.4))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))

                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.white)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(Color.black.opacity(0.55)))
                        }
                        Spacer()
                    }
                    .padding(6)
                } else {
                    RoundedRectangle(cornerRadius: BanBanRadius.medium)
                        .fill(Color.banbanInput.opacity(0.4))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: BanBanRadius.medium)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                .foregroundStyle(Color.banbanBorder)
                        )
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .light))
                                .foregroundStyle(Color.banbanMutedForeground)
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// 编辑模式回填：按 draft.photoCount 恢复占位图
    private func syncPhotosFromDraft() {
        guard photos.allSatisfy({ $0 == nil }) else { return }
        for index in 0..<min(draft.photoCount, photos.count) {
            photos[index] = URL(string: "https://picsum.photos/seed/banban-photo\(index + 1)/600/600")
        }
    }
}

/// 出行工具数量步进（− N +）
private struct TransportStepper: View {
    let tool: String
    @Binding var counts: [String: Int]

    var body: some View {
        let value = counts[tool] ?? 1
        HStack(spacing: 0) {
            Button {
                if value > 1 { counts[tool] = value - 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.banbanMutedForeground)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Text("\(value)")
                .font(BanBanFont.body)
                .foregroundStyle(Color.banbanForeground)
                .frame(width: 22)
            Button {
                if value < 9 { counts[tool] = value + 1 }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.banbanPrimary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(Capsule().fill(Color.banbanCard))
        .overlay(Capsule().strokeBorder(Color.banbanBorder, lineWidth: 1))
    }
}
