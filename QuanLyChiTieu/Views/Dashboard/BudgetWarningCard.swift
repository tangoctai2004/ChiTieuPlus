//
//  BudgetWarningCard.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI
import CoreData

struct BudgetWarningCard: View {
    let budget: Budget
    
    private var category: Category? {
        guard let categoryID = budget.categoryID else { return nil }
        return DataRepository.shared.fetchCategory(by: categoryID)
    }
    
    private var categoryName: String {
        if let category = category {
            return category.name ?? "Không xác định"
        }
        return "Tổng chi tiêu"
    }
    
    private var warningColor: Color {
        budget.warningStatus.color
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: budget.usagePercentage >= 1.0 ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(warningColor)
                .frame(width: 36, height: 36)
                .background(warningColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                if let category = category {
                    Text(LocalizedStringKey(category.name ?? "common_no_name"))
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundColor(.primary)
                } else {
                    Text("Tổng chi tiêu")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundColor(.primary)
                }
                
                Text("\(Int(budget.usagePercentage * 100))% - \(AppUtils.formattedCurrency(budget.spentAmount)) / \(AppUtils.formattedCurrency(budget.amount))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(warningColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(warningColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

