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
    
    // Cache bindings để tránh tạo mới mỗi lần và giảm navigation updates
    private var homePathBinding: Binding<NavigationPath>!
    private var categoryPathBinding: Binding<NavigationPath>!
    private var addPathBinding: Binding<NavigationPath>!
    private var dashboardPathBinding: Binding<NavigationPath>!
    private var settingsPathBinding: Binding<NavigationPath>!
    
    private init() {
        // Khởi tạo bindings một lần duy nhất
        homePathBinding = Binding(
            get: { self.homePath },
            set: { self.homePath = $0 }
        )
        categoryPathBinding = Binding(
            get: { self.categoryPath },
            set: { self.categoryPath = $0 }
        )
        addPathBinding = Binding(
            get: { self.addPath },
            set: { self.addPath = $0 }
        )
        dashboardPathBinding = Binding(
            get: { self.dashboardPath },
            set: { self.dashboardPath = $0 }
        )
        settingsPathBinding = Binding(
            get: { self.settingsPath },
            set: { self.settingsPath = $0 }
        )
    }
    
    // Lấy path cho tab cụ thể
    // Sử dụng cached bindings để tránh tạo Binding mới mỗi lần và giảm navigation updates
    func path(for tab: Int) -> Binding<NavigationPath> {
        switch tab {
        case 1: 
            return homePathBinding
        case 2:
            return categoryPathBinding
        case 3:
            return addPathBinding
        case 4:
            return dashboardPathBinding
        case 5:
            return settingsPathBinding
        default:
            return homePathBinding
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

