//
//  SettingsCardView.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

struct SettingsCardView<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content
    
    init(title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
        }
    }
}


