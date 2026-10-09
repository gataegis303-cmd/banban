//
//  LoginView.swift
//  BanBan · 手机号登录
//
//  对应 pages/login.html：+86 分隔组合输入、协议行、验证码按钮（默认禁用）
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phone = ""
    @State private var agreed = false

    private var isValid: Bool {
        phone.count == 11 && agreed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CircleIconButton(icon: "chevron.left") { dismiss() }

            VStack(alignment: .leading, spacing: 8) {
                Text("手机号登录")
                    .font(BanBanFont.h1)
                    .foregroundStyle(Color.banbanForeground)
                Text("未注册手机号验证后将自动创建账号")
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanMutedForeground)
            }
            .padding(.top, 8)

            // +86 组合输入
            HStack(spacing: 12) {
                Text("+86")
                    .font(BanBanFont.bodyLarge)
                    .foregroundStyle(Color.banbanForeground)
                Rectangle()
                    .fill(Color.banbanBorder)
                    .frame(width: 1, height: 20)
                TextField("请输入手机号", text: $phone)
                    .font(BanBanFont.bodyLarge)
                    .foregroundStyle(Color.banbanForeground)
                    .keyboardType(.numberPad)
                    .onChange(of: phone) { newValue in
                        phone = String(newValue.filter(\.isNumber).prefix(11))
                    }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color.banbanInput.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: BanBanRadius.medium)
                    .strokeBorder(Color.banbanBorder, lineWidth: 1)
            )
            .padding(.top, 32)

            // 协议行
            Button {
                agreed.toggle()
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: agreed ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundStyle(agreed ? Color.banbanPrimary : Color.banbanMutedForeground)
                    Text("已阅读并同意《用户协议》和《隐私政策》")
                        .font(BanBanFont.caption)
                        .foregroundStyle(Color.banbanMutedForeground)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 16)

            Spacer()

            NavigationLink(value: AuthRoute.verifyID) {
                PrimaryButtonLabel(title: "获取验证码")
            }
            .disabled(!isValid)

            HStack(spacing: 4) {
                Text("遇到问题？")
                    .foregroundStyle(Color.banbanMutedForeground)
                Text("联系客服")
                    .foregroundStyle(Color.banbanPrimary)
                    .fontWeight(.medium)
            }
            .font(BanBanFont.caption)
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .background(Color.banbanBackground)
        .navigationBarBackButtonHidden(true)
    }
}
