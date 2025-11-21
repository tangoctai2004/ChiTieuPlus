//
//  RecurringTransactionCardView.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

struct RecurringTransactionCardView: View {
    let recurring: RecurringTransaction
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var category: Category? {
        guard let categoryID = recurring.categoryID else { return nil }
        return DataRepository.shared.fetchCategory(by: categoryID)
    }
    
    private var categoryName: String {
        if let category = category {
            return category.name ?? "Không xác định"
        }
        return "Không có danh mục"
    }
    
    private var transactionColor: Color {
        recurring.type == "income" ? AppColors.incomeColor : AppColors.expenseColor
    }
    
    private var nextDueDateString: String {
        guard let nextDueDate = recurring.nextDueDate else { return "Không xác định" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: nextDueDate)
    }
    
    private var daysUntilDue: Int? {
        guard let nextDueDate = recurring.nextDueDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDate = calendar.startOfDay(for: nextDueDate)
        let components = calendar.dateComponents([.day], from: today, to: dueDate)
        return components.day
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: recurring.type == "income" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(transactionColor)
                        .frame(width: 44, height: 44)
                        .background(transactionColor.opacity(0.15))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recurring.title ?? "Giao dịch định kỳ")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            if let category = category {
                                Image(systemName: category.iconName ?? "folder")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text(LocalizedStringKey(category.name ?? "common_no_name"))
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Không có danh mục")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
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
                
                // Amount and Frequency
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Số tiền")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(AppUtils.formattedCurrency(recurring.amount))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(transactionColor)
                    }
                    
                    HStack {
                        Text("Tần suất")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(recurring.transactionFrequency.localizedName)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                
                // Next Due Date
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(NSLocalizedString("recurring_next_due", comment: ""))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let days = daysUntilDue {
                            if days < 0 {
                                Text(String(format: NSLocalizedString("recurring_overdue", comment: ""), abs(days)))
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundColor(AppColors.expenseColor)
                            } else if days == 0 {
                                Text(NSLocalizedString("recurring_today", comment: ""))
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundColor(.orange)
                            } else if days <= 3 {
                                Text(String(format: NSLocalizedString("recurring_days_remaining", comment: ""), days))
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundColor(.orange)
                            } else {
                                Text(nextDueDateString)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                        } else {
                            Text(nextDueDateString)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if recurring.isDue {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                            Text(NSLocalizedString("recurring_due_notification", comment: ""))
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // End Date (if exists)
                if let endDate = recurring.endDate {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(NSLocalizedString("recurring_end_date_prefix", comment: "")) \(formatDate(endDate))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

