//
//  AppearanceSettings.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light = "settings_appearance_light"
    case dark = "settings_appearance_dark"
    case system = "settings_appearance_system"
    
    var id: Self { self }
    
    var localizedName: LocalizedStringKey {
        return LocalizedStringKey(self.rawValue)
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // nil means use system default
        }
    }
}

class AppearanceSettings: ObservableObject {
    static let shared = AppearanceSettings()
    
    @AppStorage("selectedAppearance") var selectedAppearance: String = AppearanceMode.system.rawValue
    
    var currentAppearance: AppearanceMode {
        AppearanceMode(rawValue: selectedAppearance) ?? .system
    }
    
    var colorScheme: ColorScheme? {
        currentAppearance.colorScheme
    }
    
    private init() {}
}


