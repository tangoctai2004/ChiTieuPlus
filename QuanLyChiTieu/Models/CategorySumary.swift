//
//  CategorySummary.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 23/10/25.
//

import Foundation
import SwiftUI

struct CategorySummary: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let total: Double
    let percentage: Double
    let iconName: String
    let color: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(total)
        hasher.combine(iconName)
    }
    
    static func == (lhs: CategorySummary, rhs: CategorySummary) -> Bool {
        return lhs.name == rhs.name &&
               lhs.total == rhs.total &&
               lhs.iconName == rhs.iconName
    }
}
