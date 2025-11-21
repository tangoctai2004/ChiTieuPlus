//
//  NavigationCoordinator.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    // Navigation paths cho từng tab
    @Published var homePath = NavigationPath()
    @Published var categoryPath = NavigationPath()
    @Published var addPath = NavigationPath()
    @Published var dashboardPath = NavigationPath()
    @Published var settingsPath = NavigationPath()
    
    private init() {}
    
    // Lấy path cho tab cụ thể
    func path(for tab: Int) -> Binding<NavigationPath> {
        switch tab {
        case 1: 
            return Binding(
                get: { self.homePath },
                set: { self.homePath = $0 }
            )
        case 2:
            return Binding(
                get: { self.categoryPath },
                set: { self.categoryPath = $0 }
            )
        case 3:
            return Binding(
                get: { self.addPath },
                set: { self.addPath = $0 }
            )
        case 4:
            return Binding(
                get: { self.dashboardPath },
                set: { self.dashboardPath = $0 }
            )
        case 5:
            return Binding(
                get: { self.settingsPath },
                set: { self.settingsPath = $0 }
            )
        default:
            return Binding(
                get: { self.homePath },
                set: { self.homePath = $0 }
            )
        }
    }
    
    // Pop về root cho tab cụ thể
    func popToRoot(for tab: Int) {
        switch tab {
        case 1:
            homePath = NavigationPath()
        case 2:
            categoryPath = NavigationPath()
        case 3:
            addPath = NavigationPath()
        case 4:
            dashboardPath = NavigationPath()
        case 5:
            settingsPath = NavigationPath()
        default: break
        }
    }
    
    // Pop về root cho tất cả tabs
    func popAllToRoot() {
        homePath = NavigationPath()
        categoryPath = NavigationPath()
        addPath = NavigationPath()
        dashboardPath = NavigationPath()
        settingsPath = NavigationPath()
    }
}

