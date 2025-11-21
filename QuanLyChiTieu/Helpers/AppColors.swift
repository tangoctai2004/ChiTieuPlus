//
//  AppColors.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

// Hệ thống màu sắc thích ứng với light/dark mode
struct AppColors {
    
    // MARK: - Background Colors
    static var background: Color {
        Color(.systemBackground)
    }
    
    static var secondaryBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    static var groupedBackground: Color {
        Color(.systemGroupedBackground)
    }
    
    static var secondaryGroupedBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }
    
    // MARK: - Card Colors
    static var cardBackground: Color {
        Color(.systemBackground)
    }
    
    static var cardShadow: Color {
        Color.primary.opacity(0.1)
    }
    
    // MARK: - Text Colors
    static var primaryText: Color {
        Color.primary
    }
    
    static var secondaryText: Color {
        Color.secondary
    }
    
    // MARK: - Accent Colors (Income/Expense)
    static var incomeColor: Color {
        // Green for income - works well in both modes
        Color(light: Color(red: 0.2, green: 0.7, blue: 0.3), 
              dark: Color(red: 0.3, green: 0.8, blue: 0.4))
    }
    
    static var expenseColor: Color {
        // Red for expense - adjusted for dark mode
        Color(light: Color(red: 0.9, green: 0.2, blue: 0.2),
              dark: Color(red: 1.0, green: 0.3, blue: 0.3))
    }
    
    // MARK: - Button Colors
    static var primaryButton: Color {
        Color(light: Color(red: 0.2, green: 0.7, blue: 0.3),
              dark: Color(red: 0.3, green: 0.8, blue: 0.4))
    }
    
    static var primaryButtonDisabled: Color {
        Color.gray.opacity(0.5)
    }
    
    static var destructiveButton: Color {
        Color(light: Color(red: 0.9, green: 0.2, blue: 0.2),
              dark: Color(red: 1.0, green: 0.3, blue: 0.3))
    }
    
    // MARK: - Tab Bar Colors
    static var tabBarBackground: Color {
        Color(.systemBackground)
    }
    
    static var tabBarInactive: Color {
        Color.gray
    }
    
    // MARK: - Gradient Colors (for branding)
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(light: Color(red: 0.9, green: 0.2, blue: 0.2),
                      dark: Color(red: 1.0, green: 0.3, blue: 0.3)),
                Color(light: Color(red: 0.6, green: 0.2, blue: 0.8),
                      dark: Color(red: 0.7, green: 0.3, blue: 0.9))
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Border Colors
    static var borderColor: Color {
        Color(light: Color.gray.opacity(0.3),
              dark: Color.gray.opacity(0.5))
    }
    
    // MARK: - Shadow Colors
    static var shadowColor: Color {
        Color(light: Color.black.opacity(0.1),
              dark: Color.black.opacity(0.3))
    }
    
    // MARK: - Section Header Colors
    static var sectionHeaderBackground: Color {
        Color(.systemGroupedBackground)
    }
}

// Extension để tạo Color thích ứng với light/dark mode
extension Color {
    init(light: Color, dark: Color) {
        #if os(iOS)
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #else
        self.init(light)
        #endif
    }
}

