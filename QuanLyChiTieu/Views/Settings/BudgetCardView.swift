//
//  BudgetCardView.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI
import CoreData

struct BudgetCardView: View {
    let budget: Budget
    let onTap: () -> Void
    let onDelete: () -> Void
    
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
    
    private var categoryIcon: String {
        return category?.iconName ?? "creditcard"
    }
    
    private var warningColor: Color {
        budget.warningStatus.color
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(warningColor)
                        .frame(width: 44, height: 44)
                        .background(warningColor.opacity(0.15))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let category = category {
                            Text(LocalizedStringKey(category.name ?? "common_no_name"))
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.primary)
                        } else {
                            Text("Tổng chi tiêu")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Text(budget.budgetPeriod.localizedName)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive, action: onDelete) {
                            Label("Xóa", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Đã sử dụng")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int((budget.usagePercentage.isFinite && !budget.usagePercentage.isNaN ? budget.usagePercentage : 0) * 100))%")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(warningColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(warningColor)
                                .frame(width: geometry.size.width * min(budget.usagePercentage, 1.0), height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("Đã chi: \(AppUtils.formattedCurrency(budget.spentAmount))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Ngân sách: \(AppUtils.formattedCurrency(budget.amount))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    if budget.usagePercentage >= 1.0 {
                        Text("Đã vượt quá ngân sách!")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(AppColors.expenseColor)
                    } else {
                        Text("Còn lại: \(AppUtils.formattedCurrency(budget.remainingAmount))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    if let endDate = budget.currentPeriodEndDate {
                        let calendar = Calendar.current
                        let daysRemaining = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
                        
                        if daysRemaining > 0 {
                            Text("Còn \(daysRemaining) ngày trong kỳ")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        } else if daysRemaining == 0 {
                            Text("Hôm nay là ngày cuối kỳ")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Warning Status
                if budget.warningStatus != .normal {
                    HStack {
                        Image(systemName: warningIcon)
                            .font(.system(size: 14))
                            .foregroundColor(warningColor)
                        Text(warningMessage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(warningColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(warningColor.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.cardBackground)
                    .shadow(color: AppColors.cardShadow, radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var warningIcon: String {
        switch budget.warningStatus {
        case .caution: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        case .exceeded: return "xmark.circle.fill"
        case .normal: return ""
        }
    }
    
    private var warningMessage: String {
        switch budget.warningStatus {
        case .caution: return "Đã sử dụng hơn 80% ngân sách"
        case .warning: return "Đã sử dụng hơn 90% ngân sách"
        case .critical: return "Sắp hết ngân sách!"
        case .exceeded: return "Đã vượt quá ngân sách!"
        case .normal: return ""
        }
    }
}

