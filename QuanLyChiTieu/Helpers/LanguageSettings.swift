//
//  LanguageSettings.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 24/10/25.
//

import SwiftUI

class LanguageSettings: ObservableObject {
    @AppStorage("selectedLanguage") var selectedLanguage: String = "vi"
}
