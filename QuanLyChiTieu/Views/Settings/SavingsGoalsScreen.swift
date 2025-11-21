//
//  SavingsGoalsScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

struct SavingsGoalsScreen: View {
    @StateObject private var viewModel = SavingsGoalViewModel()
    @State private var isShowingAddGoal = false
    @State private var goalToEdit: SavingsGoal?
    @State private var goalToDelete: SavingsGoal?
    @State private var showDeleteAlert = false
    @State private var goalToExtend: SavingsGoal?
    @State private var showExtendAlert = false
    
    var body: some View {
        AppColors.groupedBackground
            .ignoresSafeArea()
            .overlay(
                ScrollView {
                    VStack(spacing: 20) {
                        // Active Goals Section
                        if !viewModel.activeGoals.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Mục tiêu đang thực hiện")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(viewModel.activeGoals) { goal in
                                        SavingsGoalCardView(
                                            goal: goal,
                                            onTap: {
                                                goalToEdit = goal
                                            },
                                            onDelete: {
                                                goalToDelete = goal
                                                showDeleteAlert = true
                                            },
                                            onComplete: {
                                                viewModel.completeGoal(goal)
                                            },
                                            onExtend: {
                                                goalToExtend = goal
                                                showExtendAlert = true
                                            }
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }
                        
                        // Completed Goals Section
                        if !viewModel.completedGoals.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Mục tiêu đã hoàn thành")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(viewModel.completedGoals) { goal in
                                        SavingsGoalCardView(
                                            goal: goal,
                                            onTap: {
                                                goalToEdit = goal
                                            },
                                            onDelete: {
                                                goalToDelete = goal
                                                showDeleteAlert = true
                                            },
                                            onComplete: {
                                                viewModel.completeGoal(goal)
                                            },
                                            onExtend: {
                                                goalToExtend = goal
                                                showExtendAlert = true
                                            }
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        
                        // Empty State
                        if viewModel.savingsGoals.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "target")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                
                                Text("Chưa có mục tiêu tiết kiệm")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                Text("Tạo mục tiêu đầu tiên để bắt đầu tiết kiệm!")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 100)
                        }
                    }
                    .padding(.bottom, 20)
                }
            )
            .navigationTitle("Mục tiêu tiết kiệm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingAddGoal = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .tint(.black)
                }
            }
            .sheet(isPresented: $isShowingAddGoal) {
                SavingsGoalFormView(
                    goal: nil,
                    onSave: { title, targetAmount, targetDate, iconName, color in
                        viewModel.addGoal(
                            title: title,
                            targetAmount: targetAmount,
                            targetDate: targetDate,
                            iconName: iconName,
                            color: color
                        )
                        isShowingAddGoal = false
                    }
                )
            }
            .sheet(item: $goalToEdit) { goal in
                SavingsGoalFormView(
                    goal: goal,
                    onSave: { title, targetAmount, targetDate, iconName, color in
                        viewModel.updateGoal(
                            goal,
                            title: title,
                            targetAmount: targetAmount,
                            targetDate: targetDate,
                            iconName: iconName,
                            color: color
                        )
                        goalToEdit = nil
                    }
                )
            }
            .onAppear {
                viewModel.loadSavingsGoals()
                viewModel.updateAllGoalsProgress()
                // Lên lịch lại thông báo cho tất cả mục tiêu
                viewModel.rescheduleAllNotifications()
                
                // Debug: Kiểm tra quyền và in ra thông báo đang chờ
                #if DEBUG
                NotificationManager.shared.checkNotificationPermission()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    NotificationManager.shared.printAllPendingNotifications()
                }
                #endif
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TransactionDidChange"))) { _ in
                // Update progress when transactions change
                viewModel.updateAllGoalsProgress()
            }
            .alert("Xóa mục tiêu", isPresented: $showDeleteAlert) {
                Button("Hủy", role: .cancel) { }
                Button("Xóa", role: .destructive) {
                    if let goal = goalToDelete {
                        viewModel.deleteGoal(goal)
                        goalToDelete = nil
                    }
                }
            } message: {
                Text("Bạn có chắc muốn xóa mục tiêu này? Hành động này không thể hoàn tác.")
            }
            .alert(NSLocalizedString("savings_goal_extend_alert_title", comment: ""), isPresented: $showExtendAlert) {
                Button(NSLocalizedString("savings_goal_extend_alert_no", comment: ""), role: .cancel) {
                    goalToExtend = nil
                }
                Button(NSLocalizedString("savings_goal_extend_alert_yes", comment: "")) {
                    // Không cần làm gì, chỉ cần mở sheet
                }
            } message: {
                if let goal = goalToExtend {
                    Text(String(format: NSLocalizedString("savings_goal_extend_alert_message", comment: ""), goal.title ?? ""))
                }
            }
            .sheet(item: $goalToExtend) { goal in
                SavingsGoalExtendView(goal: goal) { newDate in
                    viewModel.extendGoal(goal, newTargetDate: newDate)
                    goalToExtend = nil
                }
            }
    }
}

struct SavingsGoalCardView: View {
    let goal: SavingsGoal
    let onTap: () -> Void
    let onDelete: () -> Void
    let onComplete: (() -> Void)?
    let onExtend: (() -> Void)?
    
    private var progressColor: Color {
        // Sử dụng màu từ goal.color nếu có, nếu không thì dùng màu mặc định
        if let colorString = goal.color {
            return colorFromString(colorString)
        }
        
        // Fallback: màu dựa trên trạng thái
        if goal.isCompleted {
            return AppColors.incomeColor
        } else if goal.isOverdue {
            return AppColors.expenseColor
        } else {
            return AppColors.primaryButton
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "blue": return .blue
        case "green": return AppColors.incomeColor
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "red": return AppColors.expenseColor
        case "teal": return .teal
        case "indigo": return .indigo
        default: return AppColors.primaryButton
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: goal.iconName ?? "target")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(progressColor)
                        .frame(width: 44, height: 44)
                        .background(progressColor.opacity(0.15))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title ?? "Mục tiêu")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if let targetDate = goal.targetDate {
                            Text("Đến: \(formatDate(targetDate))")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        if goal.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.incomeColor)
                        } else if goal.isOverdue {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.expenseColor)
                        }
                        
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
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tiến độ")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(goal.progress * 100))%")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(progressColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(progressColor)
                                .frame(width: geometry.size.width * goal.progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("Đã tiết kiệm: \(AppUtils.formattedCurrency(goal.currentAmount))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Mục tiêu: \(AppUtils.formattedCurrency(goal.targetAmount))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    if let daysRemaining = goal.daysRemaining, !goal.isCompleted {
                        if daysRemaining > 0 {
                            Text("Còn lại \(daysRemaining) ngày")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(daysRemaining < 7 ? AppColors.expenseColor : .secondary)
                        } else if daysRemaining == 0 {
                            Text("Hôm nay là hạn chót!")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(AppColors.expenseColor)
                        } else {
                            Text("Đã quá hạn \(abs(daysRemaining)) ngày")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(AppColors.expenseColor)
                        }
                    }
                }
                
                // Complete Button (chỉ hiện khi đạt 100% và chưa có giao dịch)
                if goal.isCompleted && goal.progress >= 1.0 && !goal.hasCompletedTransaction {
                    Button(action: {
                        onComplete?()
                    }) {
                        HStack {
                            Spacer()
                            Text(NSLocalizedString("savings_goal_complete_button", comment: ""))
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(AppColors.incomeColor)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                
                // Extend Button (chỉ hiện khi đã hết hạn và chưa hoàn thành)
                if goal.isOverdue && !goal.isCompleted {
                    Button(action: {
                        onExtend?()
                    }) {
                        HStack {
                            Spacer()
                            Text(NSLocalizedString("savings_goal_extend_button", comment: ""))
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(AppColors.primaryButton)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
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

