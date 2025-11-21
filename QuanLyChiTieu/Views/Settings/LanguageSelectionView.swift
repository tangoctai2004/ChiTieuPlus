//
//  LanguageSelectionView.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 24/10/25.
//

import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageSettings: LanguageSettings
    @Environment(\.dismiss) var dismiss
    
    private let languages: [(code: String, name: String, flag: String)] = [
        ("vi", "Tiếng Việt", "🇻🇳"),
        ("en", "English", "🇺🇸")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(languages, id: \.code) { language in
                    LanguageRowView(
                        flag: language.flag,
                        name: language.name,
                        isSelected: languageSettings.selectedLanguage == language.code
                    ) {
                        languageSettings.selectedLanguage = language.code
                        dismiss()
                    }
                }
            }
            .padding()
        }
        .background(AppColors.groupedBackground.ignoresSafeArea())
        .navigationTitle(Text("settings_row_language"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LanguageRowView: View {
    let flag: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(flag)
                    .font(.system(size: 32))
                
                Text(name)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primaryButton)
                }
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.primaryButton : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
