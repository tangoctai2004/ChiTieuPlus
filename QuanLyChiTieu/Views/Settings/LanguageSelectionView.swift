//
//  LanguageSelectionView.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 24/10/25.
//

import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageSettings: LanguageSettings
    
    var body: some View {
        List {
            Button(action: {
                languageSettings.selectedLanguage = "vi"
            }) {
                HStack {
                    Text("Tiếng Việt")
                        .foregroundColor(.primary)
                    Spacer()
                    if languageSettings.selectedLanguage == "vi" {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Button(action: {
                languageSettings.selectedLanguage = "en"
            }) {
                HStack {
                    Text("English")
                        .foregroundColor(.primary)
                    Spacer()
                    if languageSettings.selectedLanguage == "en" {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle(Text("settings_row_language"))
    }
}
