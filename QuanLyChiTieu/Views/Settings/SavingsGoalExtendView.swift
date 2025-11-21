//
//  SavingsGoalExtendView.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

struct SavingsGoalExtendView: View {
    let goal: SavingsGoal
    let onSave: (Date) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var targetDate: Date
    
    init(goal: SavingsGoal, onSave: @escaping (Date) -> Void) {
        self.goal = goal
        self.onSave = onSave
        _targetDate = State(initialValue: goal.targetDate ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Target Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("savings_goal_new_target_date_label", comment: ""))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        DatePicker("", selection: $targetDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.cardBackground)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(AppColors.groupedBackground.ignoresSafeArea())
            .navigationTitle(NSLocalizedString("savings_goal_extend_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                    .tint(.black)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        onSave(targetDate)
                        dismiss()
                    }
                    .tint(.black)
                }
            }
        }
    }
}

